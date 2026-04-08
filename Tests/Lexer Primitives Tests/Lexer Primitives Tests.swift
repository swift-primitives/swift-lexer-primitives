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

import Testing
import Lexer_Primitives

@Suite("Lexer.Scanner")
struct LexerScannerTests {

    // MARK: - Helpers

    private func kinds(
        from source: String
    ) -> (kinds: [Token.Kind], diagnostics: [Lexer.Error]) {
        var source = source
        return source.withUTF8 { utf8 in
            let span = unsafe Span(
                _unsafeStart: utf8.baseAddress!,
                count: utf8.count
            )
            var scanner = Lexer.Scanner(span)
            var kinds: [Token.Kind] = []
            var diagnostics: [Lexer.Error] = []
            while let lexeme = scanner.next(diagnostics: &diagnostics) {
                kinds.append(lexeme.kind)
            }
            return (kinds, diagnostics)
        }
    }

    // MARK: - Empty Input

    @Test func emptyInput() {
        let (kinds, diagnostics) = kinds(from: "")
        #expect(kinds == [.endOfFile])
        #expect(diagnostics.isEmpty)
    }

    // MARK: - Identifiers and Keywords

    @Test func identifier() {
        let (kinds, _) = kinds(from: "foo")
        #expect(kinds == [.identifier, .endOfFile])
    }

    @Test func keyword() {
        let (kinds, _) = kinds(from: "let")
        #expect(kinds == [.keyword(.let), .endOfFile])
    }

    @Test func multipleKeywords() {
        let (kinds, _) = kinds(from: "var x")
        #expect(kinds == [.keyword(.var), .identifier, .endOfFile])
    }

    @Test func wildcard() {
        let (kinds, _) = kinds(from: "_")
        #expect(kinds == [.wildcard, .endOfFile])
    }

    @Test func identifierStartingWithUnderscore() {
        let (kinds, _) = kinds(from: "_foo")
        #expect(kinds == [.identifier, .endOfFile])
    }

    @Test func dollarIdentifier() {
        let (kinds, _) = kinds(from: "$0")
        #expect(kinds == [.dollarIdentifier, .endOfFile])
    }

    // MARK: - Integer Literals

    @Test func integerLiteral() {
        let (kinds, _) = kinds(from: "42")
        #expect(kinds == [.integerLiteral, .endOfFile])
    }

    @Test func integerWithSeparators() {
        let (kinds, _) = kinds(from: "1_000")
        #expect(kinds == [.integerLiteral, .endOfFile])
    }

    // MARK: - String Literals

    @Test func stringLiteral() {
        let (kinds, _) = kinds(from: #""hello""#)
        #expect(kinds == [.stringLiteral, .endOfFile])
    }

    @Test func unterminatedString() {
        let (kinds, diagnostics) = kinds(from: #""hello"#)
        #expect(kinds == [.stringLiteral, .endOfFile])
        #expect(diagnostics.count == 1)
    }

    // MARK: - Punctuation

    @Test func braces() {
        let (kinds, _) = kinds(from: "{}")
        #expect(kinds == [.leftBrace, .rightBrace, .endOfFile])
    }

    @Test func parens() {
        let (kinds, _) = kinds(from: "()")
        #expect(kinds == [.leftParen, .rightParen, .endOfFile])
    }

    @Test func arrow() {
        let (kinds, _) = kinds(from: "->")
        #expect(kinds == [.arrow, .endOfFile])
    }

    @Test func ellipsis() {
        let (kinds, _) = kinds(from: "...")
        #expect(kinds == [.ellipsis, .endOfFile])
    }

    // MARK: - Operators

    @Test func binaryOperator() {
        let (kinds, _) = kinds(from: "+")
        #expect(kinds == [.binaryOperator, .endOfFile])
    }

    // MARK: - Comments

    @Test func lineComment() {
        let (kinds, diagnostics) = kinds(from: "// comment\nfoo")
        #expect(kinds == [.identifier, .endOfFile])
        #expect(diagnostics.isEmpty)
    }

    @Test func blockComment() {
        let (kinds, diagnostics) = kinds(from: "/* comment */ foo")
        #expect(kinds == [.identifier, .endOfFile])
        #expect(diagnostics.isEmpty)
    }

    @Test func nestedBlockComment() {
        let (kinds, diagnostics) = kinds(from: "/* /* nested */ */ foo")
        #expect(kinds == [.identifier, .endOfFile])
        #expect(diagnostics.isEmpty)
    }

    @Test func unterminatedBlockComment() {
        let (kinds, diagnostics) = kinds(from: "/* unterminated")
        #expect(kinds == [.endOfFile])
        #expect(diagnostics.count == 1)
    }

    // MARK: - Trivia Tracking

    @Test func leadingTrivia() {
        var source = "  foo"
        source.withUTF8 { utf8 in
            let span = unsafe Span(
                _unsafeStart: utf8.baseAddress!,
                count: utf8.count
            )
            var scanner = Lexer.Scanner(span)
            var diagnostics: [Lexer.Error] = []
            let lexeme = scanner.next(diagnostics: &diagnostics)
            #expect(lexeme?.kind == .identifier)
            #expect(lexeme?.leadingTriviaLength == Text.Count(Cardinal(2)))
        }
    }

    @Test func trailingTrivia() {
        var source = "foo  \nbar"
        source.withUTF8 { utf8 in
            let span = unsafe Span(
                _unsafeStart: utf8.baseAddress!,
                count: utf8.count
            )
            var scanner = Lexer.Scanner(span)
            var diagnostics: [Lexer.Error] = []
            let lexeme = scanner.next(diagnostics: &diagnostics)
            #expect(lexeme?.kind == .identifier)
            // Trailing trivia is horizontal whitespace only — stops at newline.
            #expect(lexeme?.trailingTriviaLength == Text.Count(Cardinal(2)))
        }
    }

    // MARK: - Unknown Characters

    @Test func unknownCharacter() {
        let (kinds, diagnostics) = kinds(from: "§")
        // Multi-byte UTF-8 character — scanner advances past each byte.
        #expect(kinds.contains(.unknown))
        #expect(!diagnostics.isEmpty)
    }

    // MARK: - Mixed Input

    @Test func simpleDeclaration() {
        let (kinds, _) = kinds(from: "let x = 42")
        #expect(kinds == [
            .keyword(.let),
            .identifier,
            .equal,
            .integerLiteral,
            .endOfFile
        ])
    }

    @Test func functionSignature() {
        let (kinds, _) = kinds(from: "func f() -> Int")
        #expect(kinds == [
            .keyword(.func),
            .identifier,
            .leftParen,
            .rightParen,
            .arrow,
            .identifier, // "Int" is an identifier, not a keyword
            .endOfFile
        ])
    }
}
