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
    /// A structured piece of non-token content.
    ///
    /// Trivia represents whitespace, newlines, and comments that appear between
    /// tokens. While ``Lexeme`` carries trivia as opaque byte lengths (cheap,
    /// always available), `Trivia` provides structured classification when
    /// detailed analysis is needed.
    ///
    /// ## Precedent
    ///
    /// swift-syntax has `TriviaPiece` with similar cases. At the primitives
    /// level, we define the vocabulary; a full trivia parser is a higher-layer
    /// concern.
    ///
    /// ## Design
    ///
    /// Whitespace pieces use ``Text/Count`` to represent consecutive runs
    /// (e.g., 4 spaces = `.space(4)`). Since spaces and tabs are single-byte
    /// ASCII characters, the count equals the byte count.
    ///
    /// Newline pieces are individual (one per newline sequence) because each
    /// newline is semantically significant (line boundaries).
    ///
    /// Comment pieces use ``Text/Range`` because the comment text varies and
    /// must be locatable in the source buffer.
    public enum Trivia: Sendable, Equatable, Hashable {
        /// A run of consecutive space characters (U+0020).
        case space(Text.Count)

        /// A run of consecutive tab characters (U+0009).
        case tab(Text.Count)

        /// A line feed character (U+000A).
        case newline

        /// A carriage return character (U+000D).
        case carriageReturn

        /// A carriage return followed by a line feed (U+000D U+000A).
        case carriageReturnLineFeed

        /// A line comment (`//` through end of line).
        case lineComment(Text.Range)

        /// A block comment (`/*` through `*/`), possibly nested.
        case blockComment(Text.Range)
    }
}
