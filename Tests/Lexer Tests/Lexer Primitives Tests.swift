import Byte
import Cardinal
import Lexer
import Testing
import Text
import Token

extension Lexer.Scanner {
    @Suite("Lexer.Scanner")
    struct Test {

        private func kinds(
            from source: String
        ) -> (kinds: [Token.Kind], diagnostics: [Lexer.Error]) {
            let bytes: [Byte] = source.utf8.map(Byte.init(bitPattern:))
            return bytes.withUnsafeBufferPointer { buffer in
                let span = unsafe Span(_unsafeElements: buffer)
                var scanner = Lexer.Scanner(span)
                var kinds: [Token.Kind] = []
                var diagnostics: [Lexer.Error] = []
                while let lexeme = scanner.next(diagnostics: &diagnostics) {
                    kinds.append(lexeme.kind)
                }
                return (kinds, diagnostics)
            }
        }

        @Test func `empty input`() {
            let (kinds, diagnostics) = kinds(from: "")
            #expect(kinds == [.endOfFile])
            #expect(diagnostics.isEmpty)
        }

        @Test func identifier() {
            let (kinds, _) = kinds(from: "foo")
            #expect(kinds == [.identifier, .endOfFile])
        }

        @Test func keyword() {
            let (kinds, _) = kinds(from: "let")
            #expect(kinds == [.keyword(.let), .endOfFile])
        }

        @Test func `multiple keywords`() {
            let (kinds, _) = kinds(from: "var x")
            #expect(kinds == [.keyword(.var), .identifier, .endOfFile])
        }

        @Test func wildcard() {
            let (kinds, _) = kinds(from: "_")
            #expect(kinds == [.wildcard, .endOfFile])
        }

        @Test func `identifier starting with underscore`() {
            let (kinds, _) = kinds(from: "_foo")
            #expect(kinds == [.identifier, .endOfFile])
        }

        @Test func `dollar identifier`() {
            let (kinds, _) = kinds(from: "$0")
            #expect(kinds == [.dollarIdentifier, .endOfFile])
        }

        @Test func `integer literal`() {
            let (kinds, _) = kinds(from: "42")
            #expect(kinds == [.integerLiteral, .endOfFile])
        }

        @Test func `integer with separators`() {
            let (kinds, _) = kinds(from: "1_000")
            #expect(kinds == [.integerLiteral, .endOfFile])
        }

        @Test func `hex literal`() {
            let (kinds, _) = kinds(from: "0xFF")
            #expect(kinds == [.integerLiteral, .endOfFile])
        }

        @Test func `binary literal`() {
            let (kinds, _) = kinds(from: "0b1010")
            #expect(kinds == [.integerLiteral, .endOfFile])
        }

        @Test func `octal literal`() {
            let (kinds, _) = kinds(from: "0o77")
            #expect(kinds == [.integerLiteral, .endOfFile])
        }

        @Test func `floating literal`() {
            let (kinds, _) = kinds(from: "3.14")
            #expect(kinds == [.floatingLiteral, .endOfFile])
        }

        @Test func `floating literal with exponent`() {
            let (kinds, _) = kinds(from: "1e10")
            #expect(kinds == [.floatingLiteral, .endOfFile])
        }

        @Test func `floating literal with fraction and exponent`() {
            let (kinds, _) = kinds(from: "2.5e-3")
            #expect(kinds == [.floatingLiteral, .endOfFile])
        }

        @Test func `string literal`() {
            let (kinds, _) = kinds(from: #""hello""#)
            #expect(kinds == [.stringLiteral, .endOfFile])
        }

        @Test func `unterminated string`() {
            let (kinds, diagnostics) = kinds(from: #""hello"#)
            #expect(kinds == [.stringLiteral, .endOfFile])
            #expect(diagnostics.count == 1)
        }

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

        @Test func `binary operator`() {
            let (kinds, _) = kinds(from: "+")
            #expect(kinds == [.binaryOperator, .endOfFile])
        }

        @Test func `line comment`() {
            let (kinds, diagnostics) = kinds(from: "// comment\nfoo")
            #expect(kinds == [.identifier, .endOfFile])
            #expect(diagnostics.isEmpty)
        }

        @Test func `block comment`() {
            let (kinds, diagnostics) = kinds(from: "/* comment */ foo")
            #expect(kinds == [.identifier, .endOfFile])
            #expect(diagnostics.isEmpty)
        }

        @Test func `nested block comment`() {
            let (kinds, diagnostics) = kinds(from: "/* /* nested */ */ foo")
            #expect(kinds == [.identifier, .endOfFile])
            #expect(diagnostics.isEmpty)
        }

        @Test func `unterminated block comment`() {
            let (kinds, diagnostics) = kinds(from: "/* unterminated")
            #expect(kinds == [.endOfFile])
            #expect(diagnostics.count == 1)
        }

        @Test func `leading trivia`() {
            let source = "  foo"
            let bytes: [Byte] = source.utf8.map(Byte.init(bitPattern:))
            bytes.withUnsafeBufferPointer { buffer in
                let span = unsafe Span(_unsafeElements: buffer)
                var scanner = Lexer.Scanner(span)
                var diagnostics: [Lexer.Error] = []
                let lexeme = scanner.next(diagnostics: &diagnostics)
                #expect(lexeme?.kind == .identifier)
                #expect(lexeme?.leadingTriviaLength == Text.Count(Cardinal(2)))
            }
        }

        @Test func `trailing trivia`() {
            let source = "foo  \nbar"
            let bytes: [Byte] = source.utf8.map(Byte.init(bitPattern:))
            bytes.withUnsafeBufferPointer { buffer in
                let span = unsafe Span(_unsafeElements: buffer)
                var scanner = Lexer.Scanner(span)
                var diagnostics: [Lexer.Error] = []
                let lexeme = scanner.next(diagnostics: &diagnostics)
                #expect(lexeme?.kind == .identifier)

                #expect(lexeme?.trailingTriviaLength == Text.Count(Cardinal(2)))
            }
        }

        @Test func `location tracking`() {
            let source = "let\nx"
            let bytes: [Byte] = source.utf8.map(Byte.init(bitPattern:))
            bytes.withUnsafeBufferPointer { buffer in
                let span = unsafe Span(_unsafeElements: buffer)
                var scanner = Lexer.Scanner(span)
                var diagnostics: [Lexer.Error] = []

                let first = scanner.next(diagnostics: &diagnostics)
                #expect(first?.kind == .keyword(.let))

                let second = scanner.next(diagnostics: &diagnostics)
                #expect(second?.kind == .identifier)
                #expect(scanner.location.line == Text.Line.Number(2))
            }
        }

        @Test func `pound if`() {
            let (kinds, _) = kinds(from: "#if FOO")
            #expect(kinds == [.poundIf, .identifier, .endOfFile])
        }

        @Test func `pound else`() {
            let (kinds, _) = kinds(from: "#else")
            #expect(kinds == [.poundElse, .endOfFile])
        }

        @Test func `pound endif`() {
            let (kinds, _) = kinds(from: "#endif")
            #expect(kinds == [.poundEndif, .endOfFile])
        }

        @Test func `pound elseif`() {
            let (kinds, _) = kinds(from: "#elseif BAR")
            #expect(kinds == [.poundElseif, .identifier, .endOfFile])
        }

        @Test func `bare pound`() {
            let (kinds, _) = kinds(from: "#foo")
            #expect(kinds == [.pound, .identifier, .endOfFile])
        }

        @Test func `unknown character`() {
            let (kinds, diagnostics) = kinds(from: "§")

            #expect(kinds.contains(.unknown))
            #expect(!diagnostics.isEmpty)
        }

        @Test func `simple declaration`() {
            let (kinds, _) = kinds(from: "let x = 42")
            #expect(
                kinds == [
                    .keyword(.let),
                    .identifier,
                    .equal,
                    .integerLiteral,
                    .endOfFile,
                ]
            )
        }

        @Test func `function signature`() {
            let (kinds, _) = kinds(from: "func f() -> Int")
            #expect(
                kinds == [
                    .keyword(.func),
                    .identifier,
                    .leftParen,
                    .rightParen,
                    .arrow,
                    .identifier,
                    .endOfFile,
                ]
            )
        }
    }
}
