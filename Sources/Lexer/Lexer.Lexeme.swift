public import Text
public import Token

extension Lexer {

    public struct Lexeme: Sendable, Equatable, Hashable {

        public let kind: Token.Kind

        public let range: Text.Range

        public let leadingTriviaLength: Text.Count

        public let trailingTriviaLength: Text.Count

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

extension Lexer.Lexeme {

    @inlinable
    public var token: Token {
        Token(kind: kind, range: range)
    }

    @inlinable
    public var isAtEnd: Bool {
        kind == .endOfFile
    }
}
