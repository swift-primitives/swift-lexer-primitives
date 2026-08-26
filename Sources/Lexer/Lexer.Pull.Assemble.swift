extension Lexer.Pull {

    public enum Assemble {}
}

extension Lexer.Pull.Assemble {

    @inlinable
    public static func from<S: Strategy>(
        _ events: inout Lexer.Pull.Stream<S.Tokens>,
        strategy: S.Type
    ) throws(S.Tokens.Error) -> S.Value {
        guard events.isPristine else {
            return try S.build(events: &events)
        }
        return try events.consume(via: S.consume(bytes:limit:))
    }
}
