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

public import Byte_Primitives
public import Cursor_Primitive
public import Cursor_Primitives
public import Memory_Cursor_Primitives
public import Memory_Primitive
// W3 PRUNE: Cursor<Text>.storage is now Swift.Span<Byte>; the cursor
// operations dispatch on `Swift.Span: Span.`Protocol`` (the
// linchpin conformance), which must be imported DIRECTLY here for the
// inlinable call sites to see it (Finding 3/8 — MemberImportVisibility).
public import Span_Protocol_Primitives

extension Lexer {
    // SAFETY: Safe by construction — backing storage uses only stdlib
    // SAFETY: safe types via the wrapped ``Cursor``; `@safe` documents
    // SAFETY: that this type performs no unsafe operations.
    //
    // `@frozen` exposes the four-field layout (inner, source,
    // hasEmittedEndOfFile, tracker) to the optimizer for cross-module
    // specialization on hot paths (Lexer.Scanner.peek<X: Byte.Protocol>(),
    // .consume(), .next() in JSON / XML / SwiftSyntax-style parsers).
    // Per typed-index-specialization-audit v1.0.0 — the canonical Scanner
    // layout is permanent; consumers do not introspect it.
    /// A cursor-based scanner that produces ``Lexer/Lexeme`` values from
    /// borrowed UTF-8 source bytes.
    ///
    /// Scanner is `~Copyable` and `~Escapable` — it cannot be duplicated and
    /// cannot outlive the span it borrows. This mirrors the ownership model of
    /// `Cursor<Byte>` and `compnerd/xylem`'s `XML.Lexer`.
    ///
    /// Scanner wraps the institute's unified single-generic
    /// ``Cursor`` parameterized over the `Text` domain — `Cursor<Text>`,
    /// where `Text`'s `Ownership.Borrow.`Protocol`` conformance binds
    /// `Borrowed = Swift.Span<Byte>` (UTF-8 byte storage). Scanner adds
    /// text-specific overlay state (``Text/Location/Tracker`` for O(1)
    /// line:column tracking, plus an end-of-file emission flag). The
    /// substrate cursor — peek / advance / consume / position / peek(at:) /
    /// count / isAtEnd — lives in `swift-cursor-primitives` per the
    /// cursor-abstractions arc (`cursor-abstractions-l1-ecosystem.md`
    /// v1.3.0 DECISION 2026-05-17; subsequent shape refinement to
    /// single-generic per `cursor-shape-a-vs-three-worlds.md` v1.2.0).
    /// Scanner forwards these methods through `@inlinable` so call sites
    /// pay no indirection cost at known instantiations.
    ///
    /// The scanner follows the always-progress convention documented in
    /// ``Lexer/Error-swift.enum``: unrecognized or malformed input yields
    /// ``Token/Kind-swift.enum/unknown`` lexemes plus diagnostics, never an
    /// exception. Callers drain the scanner in a `while let` loop and inspect
    /// the diagnostics array afterward.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var diagnostics: [Lexer.Error] = []
    /// var scanner = Lexer.Scanner(source)
    /// while let lexeme = scanner.next(diagnostics: &diagnostics) {
    ///     // process lexeme
    /// }
    /// ```
    @frozen
    @safe
    public struct Scanner: ~Copyable, ~Escapable {
        @usableFromInline
        internal var inner: Cursor<Text>

        @usableFromInline
        internal let source: Swift.Span<Byte>

        @usableFromInline
        internal var hasEmittedEndOfFile: Bool

        @usableFromInline
        internal var tracker: Text.Location.Tracker

        /// Creates a scanner over the given borrowed UTF-8 source span.
        @inlinable
        @_lifetime(borrow source)
        public init(_ source: borrowing Swift.Span<Byte>) {
            self.source = copy source
            // W3 PRUNE: Cursor's base init consumes `DomainTag.Borrowed`
            // (== Swift.Span<Byte>); pass a copy since `source` is borrowed
            // (the deleted byte-cursor convenience init was `borrowing`).
            self.inner = Cursor<Text>(copy source)
            self.hasEmittedEndOfFile = false
            self.tracker = Text.Location.Tracker()
        }
    }
}

// MARK: - Cursor Primitives (forwarded to inner Cursor<Text>)

extension Lexer.Scanner {
    /// The current byte offset as a ``Text/Position``.
    @inlinable
    public var position: Text.Position { inner.position }

    /// The current line:column location, tracked incrementally via
    /// ``Text/Location/Tracker``.
    ///
    /// O(1) — no binary search.
    @inlinable
    public var location: Text.Location { tracker.location(at: inner.position) }

    /// The line:column location at `position`, computed by scanning source
    /// bytes for newlines.
    ///
    /// O(N) in the position offset — independent of
    /// the incremental ``location`` property's tracker state.
    ///
    /// Asymmetric with the ``location`` property by design: the property is
    /// O(1) via the incrementally-maintained tracker, suitable when callers
    /// have kept the tracker in sync via ``newline(at:)``; this method is
    /// O(N) via source scan, suitable at cold error-throw sites for parsers
    /// that elide per-byte tracker updates on the hot path.
    ///
    /// For text formats whose tokens MUST NOT contain raw newlines
    /// (e.g., JSON per RFC 8259 §7), parsers MAY skip per-newline
    /// ``newline(at:)`` updates entirely and pay this scan once per
    /// error site instead — trading O(1) error-path resolution for zero
    /// hot-path tracker arithmetic.
    @inlinable
    public func location(at position: Text.Position) -> Text.Location {
        var tracker = Text.Location.Tracker()
        var i: Text.Position = .zero
        while i < position {
            if byte(at: i) == 0x0A {
                tracker.newline(at: i)
            }
            i += .one
        }
        return tracker.location(at: position)
    }

    /// Whether the scanner has consumed the entire source.
    @inlinable
    public var isAtEnd: Bool { inner.isAtEnd }

    /// The byte at the current cursor, or `nil` at end of input.
    @inlinable
    public func peek() -> Byte? { inner.peek() }

    /// The byte at `offset` past the current cursor, or `nil` if out of
    /// range.
    @inlinable
    public func peek(at offset: Text.Count) -> Byte? { inner.peek(at: offset) }

    /// The byte at the current cursor lifted into a `Byte.`Protocol`` conformer
    /// (e.g., `ASCII.Code`), or `nil` at end of input OR if the byte cannot
    /// be lifted into `X`.
    ///
    /// ASCII-domain consumers reach for this overload by type-annotating the
    /// destination: `let code: ASCII.Code? = scanner.peek()`. The conversion
    /// goes through the byte-domain `init(_:Byte) throws(X.Error)` requirement;
    /// any thrown `X.Error` (e.g., `ASCII.Code.Error.notASCII` for bytes
    /// `>= 0x80`) collapses to `nil`. This preserves the Optional API
    /// contract — `nil` encodes "no value here," whether end-of-input or
    /// "byte exists but isn't valid `X`." Consumers that need to distinguish
    /// those cases should call the non-generic `peek() -> Byte?` and lift
    /// the byte explicitly via `try X(byte)`.
    @_disfavoredOverload
    @inlinable
    public func peek<X: Byte.`Protocol`>() -> X? {
        guard let byte = inner.peek() else { return nil }
        do throws(X.Error) {
            return try X(byte)
        } catch {
            return nil
        }
    }

    /// The byte at `offset` past the current cursor lifted into a
    /// `Byte.`Protocol`` conformer, or `nil` if out of range OR if the byte
    /// cannot be lifted into `X` (see `peek()` above for the lift semantics).
    @_disfavoredOverload
    @inlinable
    public func peek<X: Byte.`Protocol`>(at offset: Text.Count) -> X? {
        guard let byte = inner.peek(at: offset) else { return nil }
        do throws(X.Error) {
            return try X(byte)
        } catch {
            return nil
        }
    }

    /// Advances the cursor by one byte.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func advance() { inner.advance() }

    /// Advances the cursor by `count` bytes.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func advance(by count: Text.Count) { inner.advance(by: count) }

    /// Reads the byte at the current cursor and advances by one.
    ///
    /// Fused peek-then-advance for callers that have already verified
    /// the cursor is in bounds (typically via a preceding `peek()` check
    /// in a `while let` / `guard let` chain). Eliminates the redundant
    /// in-bounds check that a separate `peek()` + `advance()` pair pays.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func consume() -> Byte { inner.consume() }

    /// Records a newline at the given position to keep the location
    /// tracker in sync.
    ///
    /// Most callers drive the Scanner via the higher-level lexing
    /// helpers (`leading()`, `comment()`) which detect and report
    /// newlines automatically. External consumers that scan over text
    /// using the lower-level cursor primitives (`peek()` / `advance()` /
    /// `consume()`) MUST report newlines themselves — typically by
    /// inspecting each consumed byte for `\n` / `\r` and calling this
    /// method before the advance.
    ///
    /// Mirrors `Text.Location.Tracker.newline(at:)`: increments the
    /// line counter and sets the start of the next line to one byte
    /// past `position`. For `\r\n`, call this once for the `\r`; skip
    /// the `\n`.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func newline(at position: Text.Position) {
        tracker.newline(at: position)
    }
}

// MARK: - Internal Cursor Accessor (forwards to inner Cursor<Text>)
//
// Scanner+Lexing.swift uses `cursor` as a mutable Text.Position. After the
// cursor-abstractions migration the canonical state lives inside the wrapped
// `inner: Cursor<Text>`. This accessor preserves the legacy `cursor` /
// `cursor += .one` syntax inside the lexer hot loops by forwarding read to
// `inner.position` and write to `inner.seek(to:)`. Marked `@inlinable` so
// release builds collapse the indirection.

extension Lexer.Scanner {
    @usableFromInline
    internal var cursor: Text.Position {
        @inlinable
        get { inner.position }
        @inlinable
        @_lifetime(self: copy self)
        set { inner.seek(to: newValue) }
    }
}

// MARK: - Span Boundary
//
// Each method contains its own Int(bitPattern:) conversion per [IMPL-010].
// Raw Int never escapes a boundary method. Helpers operate against the
// stored `source` span; the wrapper's `inner: Cursor<Text>` handles
// cursor state.

extension Lexer.Scanner {
    /// Whether the source contains the given position.
    @inlinable
    @inline(__always)
    internal func contains(_ position: Text.Position) -> Bool {
        Int(bitPattern: position) < source.count
    }

    /// The byte at the given text position.
    ///
    /// Caller must ensure in-bounds.
    @inlinable
    @inline(__always)
    internal func byte(at position: Text.Position) -> Byte {
        source[Int(bitPattern: position)]
    }

    /// A sub-span between two text positions.
    @inlinable
    @inline(__always)
    @_lifetime(borrow self)
    internal func extract(
        from start: Text.Position,
        to end: Text.Position
    ) -> Swift.Span<Byte> {
        source.extracting(
            Int(bitPattern: start)..<Int(bitPattern: end)
        )
    }

    /// Typed byte count between two positions.
    ///
    /// Uses affine subtraction, returning the magnitude of the difference.
    @inlinable
    @inline(__always)
    internal func distance(
        from start: Text.Position,
        to end: Text.Position
    ) -> Text.Count {
        // `end` is the cursor, which only advances past `start`, so the affine
        // subtraction cannot underflow here — the `catch` is unreachable. `.zero`
        // is the safe default, consistent with the scanner's never-throw,
        // always-advance contract.
        do throws(Affine.Discrete.Vector.Error) {
            return try (end - start).magnitude
        } catch {
            return .zero
        }
    }
}
