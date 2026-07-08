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
    /// comments.
    ///
    /// Mirrors swift-syntax convention: leading trivia includes
    /// everything before the token, including vertical whitespace.
    @inlinable
    @_lifetime(self: copy self)
    package mutating func leading(
        diagnostics: inout [Lexer.Error]
    ) {
        while contains(cursor) {
            let b = byte(at: cursor)
            switch b {
            case .ascii.space, .ascii.tab, .ascii.vtab, .ascii.ff:
                cursor += .one

            case .ascii.cr:
                tracker.newline(at: cursor)
                cursor += .one
                // CRLF: consume the LF so it isn't counted as a second newline.
                if contains(cursor) && byte(at: cursor) == .ascii.lf {
                    cursor += .one
                }

            case .ascii.lf:
                tracker.newline(at: cursor)
                cursor += .one

            case .ascii.slash:
                if peek(at: .one) == .ascii.slash {
                    // Line comment: skip to end of line.
                    cursor += .one
                    cursor += .one
                    while contains(cursor) {
                        let c = byte(at: cursor)
                        if c == .ascii.lf || c == .ascii.cr { break }
                        cursor += .one
                    }
                } else if peek(at: .one) == .ascii.asterisk {
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
    ///
    /// Stops at newline per swift-syntax convention.
    @inlinable
    @inline(__always)
    @_lifetime(self: copy self)
    package mutating func trailing() {
        while contains(cursor) {
            let b = byte(at: cursor)
            guard b == .ascii.space || b == .ascii.tab else { return }
            cursor += .one
        }
    }

    /// Skips a block comment from `/*` through `*/`, supporting nesting.
    @inlinable
    @_lifetime(self: copy self)
    package mutating func comment(
        diagnostics: inout [Lexer.Error]
    ) {
        let start = cursor
        cursor += .one  // '/'
        cursor += .one  // '*'
        var depth = 1

        while contains(cursor) && depth > 0 {
            let b = byte(at: cursor)
            if b == .ascii.slash && peek(at: .one) == .ascii.asterisk {
                cursor += .one
                cursor += .one
                depth += 1
            } else if b == .ascii.asterisk && peek(at: .one) == .ascii.slash {
                cursor += .one
                cursor += .one
                depth -= 1
            } else if b == .ascii.cr {
                tracker.newline(at: cursor)
                cursor += .one
                if contains(cursor) && byte(at: cursor) == .ascii.lf {
                    cursor += .one
                }
            } else if b == .ascii.lf {
                tracker.newline(at: cursor)
                cursor += .one
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
    package mutating func token(
        diagnostics: inout [Lexer.Error]
    ) -> Token.Kind {
        let b = byte(at: cursor)

        if Lexer.Classify.isIdentifierStart(b) {
            return identifier()
        }
        if b == .ascii.dollarSign {
            return dollar()
        }
        if Lexer.Classify.isDecimalDigit(b) {
            return number()
        }

        switch b {
        case .ascii.doubleQuote:
            return string(diagnostics: &diagnostics)

        case .ascii.hyphen:
            if peek(at: .one) == .ascii.greaterThan {
                cursor += .one
                cursor += .one
                return .arrow
            }
            return `operator`()

        case .ascii.period:
            if peek(at: .one) == .ascii.period
                && peek(at: Text.Count(Cardinal(2))) == .ascii.period
            {
                cursor += .one
                cursor += .one
                cursor += .one
                return .ellipsis
            }
            cursor += .one
            return .period

        case .ascii.leftBrace:
            cursor += .one
            return .leftBrace

        case .ascii.rightBrace:
            cursor += .one
            return .rightBrace

        case .ascii.leftParenthesis:
            cursor += .one
            return .leftParen

        case .ascii.rightParenthesis:
            cursor += .one
            return .rightParen

        case .ascii.leftBracket:
            cursor += .one
            return .leftBracket

        case .ascii.rightBracket:
            cursor += .one
            return .rightBracket

        case .ascii.colon:
            cursor += .one
            return .colon

        case .ascii.semicolon:
            cursor += .one
            return .semicolon

        case .ascii.comma:
            cursor += .one
            return .comma

        case .ascii.atSign:
            cursor += .one
            return .atSign

        case .ascii.numberSign: return directive()

        case .ascii.backslash:
            cursor += .one
            return .backslash

        case .ascii.leftSingleQuotationMark:
            cursor += .one
            return .backtick

        case .ascii.tilde:
            cursor += .one
            return .tilde

        case .ascii.ampersand:
            cursor += .one
            return .ampersand

        case .ascii.equalsSign:
            cursor += .one
            return .equal

        case .ascii.exclamationPoint:
            cursor += .one
            return .exclamationMark

        case .ascii.questionMark:
            cursor += .one
            return .questionMark

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
    package mutating func identifier() -> Token.Kind {
        let start = cursor
        cursor += .one

        while contains(cursor)
            && Lexer.Classify.isIdentifierContinuation(byte(at: cursor))
        {
            cursor += .one
        }

        if start + .one == cursor && byte(at: start) == .ascii.underline {
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
    package mutating func dollar() -> Token.Kind {
        cursor += .one
        while contains(cursor)
            && Lexer.Classify.isDecimalDigit(byte(at: cursor))
        {
            cursor += .one
        }
        return .dollarIdentifier
    }

    /// Scans a numeric literal: decimal, hex (`0x`), binary (`0b`),
    /// octal (`0o`), or floating-point (with `.` or `e`/`E` exponent).
    @inlinable
    @_lifetime(self: copy self)
    package mutating func number() -> Token.Kind {
        var isFloat = false
        let first = byte(at: cursor)

        // Prefixed bases: 0x, 0b, 0o
        if first == .ascii.`0`, let next = peek(at: .one) {
            switch next {
            case .ascii.x, .ascii.X:
                cursor += .one
                cursor += .one
                digits(Lexer.Classify.isHexDigit)
                return .integerLiteral

            case .ascii.b, .ascii.B:
                cursor += .one
                cursor += .one
                digits(Lexer.Classify.isBinaryDigit)
                return .integerLiteral

            case .ascii.o, .ascii.O:
                cursor += .one
                cursor += .one
                digits(Lexer.Classify.isOctalDigit)
                return .integerLiteral

            default: break
            }
        }

        // Decimal digits
        digits(Lexer.Classify.isDecimalDigit)

        // Fractional part: '.' followed by digit
        if contains(cursor) && byte(at: cursor) == .ascii.period {
            if let d = peek(at: .one), Lexer.Classify.isDecimalDigit(d) {
                cursor += .one
                digits(Lexer.Classify.isDecimalDigit)
                isFloat = true
            }
        }

        // Exponent: e/E [+-]? digits
        if contains(cursor) {
            let b = byte(at: cursor)
            if b == .ascii.e || b == .ascii.E {
                cursor += .one
                if contains(cursor) {
                    let s = byte(at: cursor)
                    if s == .ascii.plus || s == .ascii.hyphen { cursor += .one }
                }
                digits(Lexer.Classify.isDecimalDigit)
                isFloat = true
            }
        }

        return isFloat ? .floatingLiteral : .integerLiteral
    }

    /// Consumes digits (and underscore separators) for the given predicate.
    @inlinable
    @_lifetime(self: copy self)
    package mutating func digits(
        _ predicate: (Byte) -> Bool
    ) {
        while contains(cursor) && predicate(byte(at: cursor)) {
            cursor += .one
        }
        while contains(cursor) && byte(at: cursor) == .ascii.underline {
            cursor += .one
            while contains(cursor) && predicate(byte(at: cursor)) {
                cursor += .one
            }
        }
    }

    /// Scans a `#`-prefixed directive (`#if`, `#else`, `#elseif`, `#endif`)
    /// or falls back to a bare `#` (`.pound`).
    @inlinable
    @_lifetime(self: copy self)
    package mutating func directive() -> Token.Kind {
        let after = cursor + .one

        // Probe identifier characters after '#' without advancing cursor.
        var end = after
        while contains(end) && Lexer.Classify.isIdentifierContinuation(byte(at: end)) {
            end += .one
        }

        // Match known directives via span comparison.
        let kind: Token.Kind? = extract(from: after, to: end)
            .withUnsafeBufferPointer { buf -> Token.Kind? in
                guard let p = unsafe buf.baseAddress else { return nil }
                switch buf.count {
                case 2 where unsafe p[0] == .ascii.i && p[1] == .ascii.f:
                    return .poundIf

                case 4
                where unsafe p[0] == .ascii.e && p[1] == .ascii.l
                    && p[2] == .ascii.s && p[3] == .ascii.e:
                    return .poundElse

                case 5
                where unsafe p[0] == .ascii.e && p[1] == .ascii.n
                    && p[2] == .ascii.d && p[3] == .ascii.i
                    && p[4] == .ascii.f:
                    return .poundEndif

                case 6
                where unsafe p[0] == .ascii.e && p[1] == .ascii.l
                    && p[2] == .ascii.s && p[3] == .ascii.e
                    && p[4] == .ascii.i && p[5] == .ascii.f:
                    return .poundElseif

                default:
                    return nil
                }
            }

        if let kind {
            cursor = end
            return kind
        }

        cursor = after
        return .pound
    }

    /// Scans a double-quoted string literal.
    ///
    /// Handles `\"` escapes.
    @inlinable
    @_lifetime(self: copy self)
    package mutating func string(
        diagnostics: inout [Lexer.Error]
    ) -> Token.Kind {
        let start = cursor
        cursor += .one

        while contains(cursor) {
            let b = byte(at: cursor)
            switch b {
            case .ascii.doubleQuote:
                cursor += .one
                return .stringLiteral

            case .ascii.backslash:
                cursor += .one
                if contains(cursor) { cursor += .one }

            case .ascii.lf, .ascii.cr:
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
    package mutating func `operator`() -> Token.Kind {
        cursor += .one
        while contains(cursor)
            && Lexer.Classify.isOperatorContinuation(byte(at: cursor))
        {
            cursor += .one
        }
        return .binaryOperator
    }
}
