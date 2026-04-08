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

// MARK: - Public Entry Point

extension Lexer.Scanner {
    /// Produces the next ``Lexer/Lexeme``, or `nil` after end-of-file has
    /// been emitted.
    ///
    /// Each call scans leading trivia (whitespace, newlines, comments),
    /// one token body, and trailing trivia (same-line horizontal whitespace).
    /// Errors are appended to `diagnostics`; the scanner always advances.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func next(
        diagnostics: inout [Lexer.Error]
    ) -> Lexer.Lexeme? {
        guard !hasEmittedEndOfFile else { return nil }

        let leadingStart = cursor
        leading(diagnostics: &diagnostics)
        let leadingLength = distance(from: leadingStart, to: cursor)

        guard contains(cursor) else {
            hasEmittedEndOfFile = true
            return Lexer.Lexeme(
                kind: .endOfFile,
                range: Text.Range(start: cursor, end: cursor),
                leadingTriviaLength: leadingLength,
                trailingTriviaLength: .zero
            )
        }

        let tokenStart = cursor
        let kind = token(diagnostics: &diagnostics)
        let tokenEnd = cursor

        let trailingStart = cursor
        trailing()
        let trailingLength = distance(from: trailingStart, to: cursor)

        return Lexer.Lexeme(
            kind: kind,
            range: Text.Range(start: tokenStart, end: tokenEnd),
            leadingTriviaLength: leadingLength,
            trailingTriviaLength: trailingLength
        )
    }
}

// MARK: - Trivia

extension Lexer.Scanner {
    /// Skips leading trivia: whitespace, newlines, line comments, block
    /// comments. Mirrors swift-syntax convention: leading trivia includes
    /// everything before the token, including vertical whitespace.
    @inlinable
    @_lifetime(self: copy self)
    internal mutating func leading(
        diagnostics: inout [Lexer.Error]
    ) {
        while contains(cursor) {
            let b = byte(at: cursor)
            switch b {
            case ASCII.Byte.space, ASCII.Byte.tab,
                 ASCII.Byte.lf, ASCII.Byte.cr,
                 ASCII.Byte.vtab, ASCII.Byte.ff:
                cursor += .one
            case ASCII.Byte.slash:
                if peek(at: .one) == ASCII.Byte.slash {
                    // Line comment: skip to end of line.
                    cursor += .one
                    cursor += .one
                    while contains(cursor) {
                        let c = byte(at: cursor)
                        if c == ASCII.Byte.lf || c == ASCII.Byte.cr { break }
                        cursor += .one
                    }
                } else if peek(at: .one) == ASCII.Byte.asterisk {
                    comment(diagnostics: &diagnostics)
                } else {
                    return
                }
            default:
                return
            }
        }
    }

    /// Skips trailing trivia: horizontal whitespace only (space, tab).
    /// Stops at newline per swift-syntax convention.
    @inlinable
    @inline(__always)
    @_lifetime(self: copy self)
    internal mutating func trailing() {
        while contains(cursor) {
            let b = byte(at: cursor)
            guard b == ASCII.Byte.space || b == ASCII.Byte.tab else { return }
            cursor += .one
        }
    }

    /// Skips a block comment from `/*` through `*/`, supporting nesting.
    @inlinable
    @_lifetime(self: copy self)
    internal mutating func comment(
        diagnostics: inout [Lexer.Error]
    ) {
        let start = cursor
        cursor += .one // '/'
        cursor += .one // '*'
        var depth = 1

        while contains(cursor) && depth > 0 {
            let b = byte(at: cursor)
            if b == ASCII.Byte.slash && peek(at: .one) == ASCII.Byte.asterisk {
                cursor += .one
                cursor += .one
                depth += 1
            } else if b == ASCII.Byte.asterisk && peek(at: .one) == ASCII.Byte.slash {
                cursor += .one
                cursor += .one
                depth -= 1
            } else {
                cursor += .one
            }
        }

        if depth > 0 {
            diagnostics.append(.unterminatedBlockComment(at: start))
        }
    }
}

// MARK: - Token Dispatch

extension Lexer.Scanner {
    /// Dispatches to the appropriate sub-scanner based on the current byte.
    @inlinable
    @_lifetime(self: copy self)
    internal mutating func token(
        diagnostics: inout [Lexer.Error]
    ) -> Token.Kind {
        let b = byte(at: cursor)

        if Lexer.Classify.isIdentifierStart(b) {
            return identifier()
        }
        if b == ASCII.Byte.dollarSign {
            return dollar()
        }
        if Lexer.Classify.isDecimalDigit(b) {
            return number()
        }

        switch b {
        case ASCII.Byte.doubleQuote:
            return string(diagnostics: &diagnostics)

        case ASCII.Byte.hyphen:
            if peek(at: .one) == ASCII.Byte.greaterThan {
                cursor += .one
                cursor += .one
                return .arrow
            }
            return `operator`()

        case ASCII.Byte.period:
            if peek(at: .one) == ASCII.Byte.period
                && peek(at: Text.Count(Cardinal(2))) == ASCII.Byte.period {
                cursor += .one
                cursor += .one
                cursor += .one
                return .ellipsis
            }
            cursor += .one
            return .period

        case ASCII.Byte.leftBrace:              cursor += .one; return .leftBrace
        case ASCII.Byte.rightBrace:             cursor += .one; return .rightBrace
        case ASCII.Byte.leftParenthesis:        cursor += .one; return .leftParen
        case ASCII.Byte.rightParenthesis:       cursor += .one; return .rightParen
        case ASCII.Byte.leftBracket:            cursor += .one; return .leftBracket
        case ASCII.Byte.rightBracket:           cursor += .one; return .rightBracket
        case ASCII.Byte.colon:                  cursor += .one; return .colon
        case ASCII.Byte.semicolon:              cursor += .one; return .semicolon
        case ASCII.Byte.comma:                  cursor += .one; return .comma
        case ASCII.Byte.atSign:                 cursor += .one; return .atSign
        case ASCII.Byte.numberSign:             cursor += .one; return .pound
        case ASCII.Byte.backslash:              cursor += .one; return .backslash
        case ASCII.Byte.leftSingleQuotationMark: cursor += .one; return .backtick
        case ASCII.Byte.tilde:                  cursor += .one; return .tilde
        case ASCII.Byte.ampersand:              cursor += .one; return .ampersand
        case ASCII.Byte.equalsSign:             cursor += .one; return .equal
        case ASCII.Byte.exclamationPoint:       cursor += .one; return .exclamationMark
        case ASCII.Byte.questionMark:           cursor += .one; return .questionMark

        case _ where Lexer.Classify.isOperatorStart(b):
            return `operator`()

        default:
            diagnostics.append(.invalidCharacter(at: cursor))
            cursor += .one
            return .unknown
        }
    }
}

// MARK: - Token Scanners

extension Lexer.Scanner {
    /// Scans an identifier or keyword.
    @inlinable
    @_lifetime(self: copy self)
    internal mutating func identifier() -> Token.Kind {
        let start = cursor
        cursor += .one

        while contains(cursor)
            && Lexer.Classify.isIdentifierContinuation(byte(at: cursor)) {
            cursor += .one
        }

        if start + .one == cursor && byte(at: start) == ASCII.Byte.underline {
            return .wildcard
        }

        let keyword: Token.Keyword? = extract(from: start, to: cursor)
            .withUnsafeBufferPointer { buffer in
                unsafe Token.Keyword(buffer)
            }

        if let keyword {
            return .keyword(keyword)
        }

        return .identifier
    }

    /// Scans a dollar identifier (`$0`, `$1`, etc.).
    @inlinable
    @_lifetime(self: copy self)
    internal mutating func dollar() -> Token.Kind {
        cursor += .one
        while contains(cursor)
            && Lexer.Classify.isDecimalDigit(byte(at: cursor)) {
            cursor += .one
        }
        return .dollarIdentifier
    }

    /// Scans a decimal integer literal.
    @inlinable
    @_lifetime(self: copy self)
    internal mutating func number() -> Token.Kind {
        while contains(cursor)
            && Lexer.Classify.isDecimalDigit(byte(at: cursor)) {
            cursor += .one
        }
        while contains(cursor) && byte(at: cursor) == ASCII.Byte.underline {
            cursor += .one
            while contains(cursor)
                && Lexer.Classify.isDecimalDigit(byte(at: cursor)) {
                cursor += .one
            }
        }
        return .integerLiteral
    }

    /// Scans a double-quoted string literal. Handles `\"` escapes.
    @inlinable
    @_lifetime(self: copy self)
    internal mutating func string(
        diagnostics: inout [Lexer.Error]
    ) -> Token.Kind {
        let start = cursor
        cursor += .one

        while contains(cursor) {
            let b = byte(at: cursor)
            switch b {
            case ASCII.Byte.doubleQuote:
                cursor += .one
                return .stringLiteral
            case ASCII.Byte.backslash:
                cursor += .one
                if contains(cursor) { cursor += .one }
            case ASCII.Byte.lf, ASCII.Byte.cr:
                diagnostics.append(.unterminatedStringLiteral(at: start))
                return .stringLiteral
            default:
                cursor += .one
            }
        }

        diagnostics.append(.unterminatedStringLiteral(at: start))
        return .stringLiteral
    }

    /// Scans an operator (one or more operator-continuation characters).
    @inlinable
    @_lifetime(self: copy self)
    internal mutating func `operator`() -> Token.Kind {
        cursor += .one
        while contains(cursor)
            && Lexer.Classify.isOperatorContinuation(byte(at: cursor)) {
            cursor += .one
        }
        return .binaryOperator
    }
}
