extension Lexer.Pull.Assemble {

    public protocol Strategy {

        associatedtype Value

        associatedtype Tokens: Lexer.Pull.Tokens

        static func consume(
            bytes: Swift.Span<Byte>,
            limit: Int
        ) throws(Tokens.Error) -> Value

        static func build(
            events: inout Lexer.Pull.Stream<Tokens>
        ) throws(Tokens.Error) -> Value
    }
}
