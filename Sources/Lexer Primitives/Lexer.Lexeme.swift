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
    /// A token with trivia metadata — the unit of output from lexical analysis.
    ///
    /// A lexeme extends ``Token`` with leading and trailing trivia byte lengths.
    /// Trivia is non-semantic content (whitespace, comments) that surrounds the
    /// token text. The lexeme carries byte lengths for trivia so that the full
    /// source span can be reconstructed without storing the trivia content.
    ///
    /// ## Layout
    ///
    /// ```
    /// |--- leading trivia ---|--- token text ---|--- trailing trivia ---|
    /// ^                      ^                  ^                       ^
    /// fullRange.start        range.start        range.end              fullRange.end
    /// ```
    ///
    /// The ``range`` covers only the token text. Leading trivia precedes the
    /// token; trailing trivia follows it. By convention (following swift-syntax):
    /// - Leading trivia includes newlines + whitespace + comments before the token.
    /// - Trailing trivia includes horizontal whitespace after the token on the
    ///   same line (stops at newline).
    ///
    /// ## Precedent
    ///
    /// swift-syntax's `Lexeme` stores exactly this: a kind, trivia byte lengths,
    /// and a text range. swiftc's `Token` carries similar metadata.
    public struct Lexeme: Sendable, Equatable, Hashable {
        /// The lexical classification of this lexeme's token.
        public let kind: Token.Kind

        /// The byte range of the token text (excluding trivia).
        public let range: Text.Range

        /// The number of bytes of leading trivia.
        public let leadingTriviaLength: Text.Count

        /// The number of bytes of trailing trivia.
        public let trailingTriviaLength: Text.Count

        /// Creates a lexeme with the given kind, range, and trivia lengths.
        @inlinable
        public init(
            kind: Token.Kind,
            range: Text.Range,
            leadingTriviaLength: Text.Count,
            trailingTriviaLength: Text.Count
        ) {
            self.kind = kind
            self.range = range
            self.leadingTriviaLength = leadingTriviaLength
            self.trailingTriviaLength = trailingTriviaLength
        }
    }
}

// MARK: - Derived Properties

extension Lexer.Lexeme {
    /// A ``Token`` derived from this lexeme (kind + range, without trivia).
    @inlinable
    public var token: Token {
        Token(kind: kind, range: range)
    }

    /// Whether this lexeme represents the end of the input.
    @inlinable
    public var isAtEnd: Bool {
        kind == .endOfFile
    }
}
