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

extension Lexer {
    /// A cursor-based scanner that produces ``Lexer/Lexeme`` values from
    /// borrowed UTF-8 source bytes.
    ///
    /// Scanner is `~Copyable` and `~Escapable` — it cannot be duplicated and
    /// cannot outlive the span it borrows. This mirrors the ownership model of
    /// `Binary.Bytes.Input.View` and `compnerd/xylem`'s `XML.Lexer`.
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
    @safe
    public struct Scanner: ~Copyable, ~Escapable {
        @usableFromInline
        internal let source: Span<UInt8>

        @usableFromInline
        internal var cursor: Text.Position

        @usableFromInline
        internal var hasEmittedEndOfFile: Bool

        @usableFromInline
        internal var tracker: Text.Location.Tracker

        @inlinable
        @_lifetime(borrow source)
        public init(_ source: borrowing Span<UInt8>) {
            self.source = copy source
            self.cursor = .zero
            self.hasEmittedEndOfFile = false
            self.tracker = Text.Location.Tracker()
        }
    }
}

// MARK: - Cursor Primitives

extension Lexer.Scanner {
    /// The current byte offset as a ``Text/Position``.
    @inlinable
    public var position: Text.Position { cursor }

    /// The current line:column location, tracked incrementally via
    /// ``Text/Location/Tracker``. O(1) — no binary search.
    @inlinable
    public var location: Text.Location { tracker.location(at: cursor) }

    /// Whether the scanner has consumed the entire source.
    @inlinable
    public var isAtEnd: Bool { !contains(cursor) }

    /// The byte at the current cursor, or `nil` at end of input.
    @inlinable
    public func peek() -> UInt8? {
        guard contains(cursor) else { return nil }
        return byte(at: cursor)
    }

    /// The byte at `offset` past the current cursor, or `nil` if out of
    /// range.
    @inlinable
    public func peek(at offset: Text.Count) -> UInt8? {
        let target = cursor + offset
        guard contains(target) else { return nil }
        return byte(at: target)
    }

    /// Advances the cursor by one byte.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func advance() {
        precondition(contains(cursor), "advance() past end of input")
        cursor += .one
    }

    /// Advances the cursor by `count` bytes.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func advance(by count: Text.Count) {
        cursor += count
    }
}

// MARK: - Span Boundary
//
// Each method contains its own Int(bitPattern:) conversion per [IMPL-010].
// Raw Int never escapes a boundary method.

extension Lexer.Scanner {
    /// Whether the source contains the given position.
    @inlinable
    @inline(__always)
    internal func contains(_ position: Text.Position) -> Bool {
        Int(bitPattern: position.rawValue) < source.count
    }

    /// The byte at the given text position. Caller must ensure in-bounds.
    @inlinable
    @inline(__always)
    internal func byte(at position: Text.Position) -> UInt8 {
        source[Int(bitPattern: position.rawValue)]
    }

    /// A sub-span between two text positions.
    @inlinable
    @inline(__always)
    @_lifetime(borrow self)
    internal func extract(
        from start: Text.Position,
        to end: Text.Position
    ) -> Span<UInt8> {
        source.extracting(
            Int(bitPattern: start.rawValue)..<Int(bitPattern: end.rawValue)
        )
    }

    /// Typed byte count between two positions.
    /// Uses affine subtraction → `.magnitude` per [INFRA-102].
    @inlinable
    @inline(__always)
    internal func distance(
        from start: Text.Position,
        to end: Text.Position
    ) -> Text.Count {
        (try! end - start).magnitude
    }
}
