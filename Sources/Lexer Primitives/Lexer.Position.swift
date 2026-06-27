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
    /// A complete position in source: the raw byte offset paired with
    /// its resolved line:column location.
    ///
    /// `Lexer.Position` is the canonical structural-format-cursor
    /// position type at L1. Format-specific aliases (e.g.,
    /// `RFC_8259.Position`) point at this single underlying shape.
    public struct Position: Equatable, Hashable, Sendable {
        /// The byte offset of the cursor.
        public let offset: Text.Position

        /// The resolved 1-based line and 1-based column at `offset`.
        public let location: Text.Location

        /// Creates a position pairing the given byte offset with its resolved line:column location.
        @inlinable
        public init(offset: Text.Position, location: Text.Location) {
            self.offset = offset
            self.location = location
        }
    }
}

extension Lexer.Position: CustomStringConvertible {
    /// A human-readable rendering of the line, column, and byte offset.
    @inlinable
    public var description: Swift.String {
        "line \(location.line), column \(location.column) (byte \(Int(bitPattern: offset)))"
    }
}
