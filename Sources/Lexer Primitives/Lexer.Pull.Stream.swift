// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-lexer-primitives open source project
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp and the swift-lexer-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

extension Lexer.Pull {
    // SAFETY: Safe by construction — backing storage uses only stdlib
    // SAFETY: safe types via the wrapped ``Lexer/Scanner``; `@safe`
    // SAFETY: documents that this type performs no unsafe operations.
    /// A pull-driven structural-event cursor over a borrowed
    /// `Swift.Span<Byte>`.
    ///
    /// `Stream` is the generic, format-agnostic substrate that
    /// surfaced inside `swift-rfc-8259` during the streaming-deserialize
    /// arc and was pulled to L1 under the [RES-018] 2026-05-14 amendment
    /// (case (c)). It parameterises over a ``Lexer/Pull/Tokens`` witness;
    /// each conforming format plugs in its own byte-rules.
    ///
    /// ## Lifecycle
    ///
    /// `~Copyable & ~Escapable` per the institute byte-cursor discipline
    /// (mirrors ``Lexer/Scanner`` and `Cursor<Byte>`). The
    /// cursor borrows the source span and cannot outlive it; this is
    /// enforced by the compiler via `@_lifetime(borrow bytes)`.
    ///
    /// ## Substrate-shared mechanics (this type)
    ///
    /// - Depth tracking with `limit` overflow guard.
    /// - Position helpers (current cursor, deferred resolution via
    ///   ``Lexer/Scanner/location(at:)``).
    /// - `isPristine` flag (`true` until the first mutating call) for
    ///   §4.3-style fast-path detection.
    /// - `isConsumed` flag for stream short-circuit semantics.
    /// - Stashed-bytes span for fast-path delegation to a sibling
    ///   non-event parser via ``consume(via:)``.
    /// - `next()` / `skip()` / `peek()` outer dispatch, delegating to
    ///   the witness's `next` / `skip(value:)` / `skip(whitespace:)`.
    ///
    /// ## Format-specific mechanics (the witness + format type)
    ///
    /// - Token-kind enum + error type.
    /// - Whitespace classification.
    /// - Per-byte token dispatch.
    /// - Per-kind value-skip implementation.
    /// - Format-specific payload-decode methods (e.g., string, number)
    ///   live as extensions on the format's typealias of `Stream`.
    @safe
    public struct Stream<Tokens: Lexer.Pull.Tokens>: ~Copyable, ~Escapable {
        /// The underlying byte cursor.
        ///
        /// Public to enable format-specific
        /// payload-decode methods defined as extensions on
        /// `Stream where Tokens == ...` in the format's own package
        /// (e.g., JSON's `currentString` / `currentNumber` in
        /// swift-rfc-8259). Mutating the cursor outside the
        /// witness's documented contract may corrupt depth/pristine
        /// invariants.
        public var scanner: Lexer.Scanner

        /// Current nesting depth — `0` at top-level; updated on each
        /// container open/close via the witness's ``Tokens/delta(for:)``.
        @usableFromInline
        internal var depth: Int

        /// Maximum allowed nesting depth.
        @usableFromInline
        internal let limit: Int

        /// `true` until the first mutating call advances the cursor.
        ///
        /// Backing storage for ``isPristine``.
        @usableFromInline
        internal var pristine: Bool

        /// `true` after a wholesale ``consume(via:)`` has advanced the
        /// cursor to end-of-input.
        ///
        /// Backing storage for ``isConsumed``.
        @usableFromInline
        internal var consumed: Bool

        /// The original byte span stashed at init time so
        /// ``consume(via:)`` can drive a sibling non-event parser
        /// without reaching into the scanner's storage.
        @usableFromInline
        internal let bytes: Swift.Span<Byte>

        /// Per-stream payload-decode scratch state owned by the
        /// witness.
        ///
        /// Format-specific extensions on `Stream` may
        /// read and mutate it for amortised-allocation payload
        /// decoding (JSON `currentString`, XML CDATA, …).
        public var scratch: Tokens.Scratch

        /// Creates a pull stream over the borrowed byte span, bounded to the given nesting `limit`.
        @inlinable
        @_lifetime(borrow bytes)
        public init(_ bytes: borrowing Swift.Span<Byte>, limit: Int = 512) {
            self.scanner = Lexer.Scanner(bytes)
            self.bytes = copy bytes
            self.depth = 0
            self.limit = limit
            self.pristine = true
            self.consumed = false
            self.scratch = Tokens.initial()
        }
    }
}

// MARK: - State accessors

extension Lexer.Pull.Stream {
    /// `true` until the first mutating call has advanced the cursor.
    ///
    /// Used by ``Lexer/Pull/Assemble/from(_:strategy:)`` to decide
    /// between the fast and slow paths.
    @inlinable
    public var isPristine: Bool { pristine }

    /// `true` after a wholesale ``consume(via:)`` has advanced the
    /// cursor to end-of-input.
    ///
    /// While `isConsumed` is `true`,
    /// ``next()`` returns `nil`.
    @inlinable
    public var isConsumed: Bool { consumed }

    /// Clear the pristine flag.
    ///
    /// Called by format-specific payload-decode methods (defined as
    /// extensions on `Stream` in the format's package) that advance
    /// the cursor without going through ``next()``. Ensures the
    /// fast-path gate in ``Lexer/Pull/Assemble/from(_:strategy:)``
    /// correctly classifies the stream as no-longer-pristine.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func touch() {
        pristine = false
    }
}

// MARK: - Position

extension Lexer.Pull.Stream {
    /// The cursor's current byte offset as a ``Text/Position``.
    @inlinable
    public var position: Text.Position { scanner.position }

    /// Build a ``Lexer/Position`` from a previously captured cursor.
    ///
    /// Line:column is computed by source scan via
    /// ``Lexer/Scanner/location(at:)`` — O(N) at the throw site,
    /// zero cost on the hot path. Capture cheap `Text.Position`
    /// before token work; call `position(at:)` only on the cold
    /// error-throw path.
    @inlinable
    public func position(at cursor: Text.Position) -> Lexer.Position {
        Lexer.Position(offset: cursor, location: scanner.location(at: cursor))
    }
}

// MARK: - Outer pull dispatch

extension Lexer.Pull.Stream {
    /// Peek the next non-whitespace byte without consuming it.
    ///
    /// Mutating: the scanner is advanced past leading whitespace per
    /// the witness's classifier, but the returned byte itself is not
    /// consumed. Idempotent in effect — calling twice returns the
    /// same byte.
    ///
    /// Returns `nil` at end of input.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func peek() -> Byte? {
        Tokens.skip(whitespace: &scanner)
        return scanner.peek()
    }

    /// Read the next structural token via the witness's dispatch.
    ///
    /// Updates `depth` via the witness's ``Tokens/delta(for:)`` and
    /// validates against `limit`. Returns `nil` at end of input.
    ///
    /// Clears ``isPristine`` on first call.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func next() throws(Tokens.Error) -> Tokens.Kind? {
        pristine = false
        guard !consumed else { return nil }
        return try Tokens.next(
            scanner: &scanner,
            depth: &depth,
            limit: limit
        )
    }

    /// Skip the current value (whatever kind) via the witness's
    /// classifier.
    ///
    /// Recurses for nested containers.
    ///
    /// Clears ``isPristine`` on first call.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func skip() throws(Tokens.Error) {
        pristine = false
        try Tokens.skip(
            value: &scanner,
            depth: &depth,
            limit: limit
        )
    }
}

// MARK: - Fast-path consume

extension Lexer.Pull.Stream {
    /// Consume the entire remaining input via a sibling parser over
    /// the stashed byte span.
    ///
    /// Marks the stream consumed; subsequent
    /// ``next()`` returns `nil`.
    ///
    /// Use this for the §4.3-style fast-path: if the caller detects
    /// "this entire input is a single value of kind V, decode it
    /// wholesale rather than walking events," it invokes
    /// `consume(via:)` with a wholesale parser. The closure receives
    /// the original byte span and the depth `limit`.
    ///
    /// The operation name is `consume` (not `parse`): the consumption
    /// is destructive to the stream — it cannot continue afterwards,
    /// unlike a side-effect-free peek/probe.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func consume<V, E: Swift.Error>(
        via parse: (Swift.Span<Byte>, Int) throws(E) -> V
    ) throws(E) -> V {
        pristine = false
        let value = try parse(bytes, limit)
        consumed = true
        return value
    }
}
