extension Lexer {

    public enum Error: Swift.Error, Sendable, Equatable, Hashable {

        case invalidCharacter(at: Text.Position)

        case unterminatedBlockComment(at: Text.Position)

        case unterminatedStringLiteral(at: Text.Position)

        case invalidEscapeSequence(at: Text.Position)

        case expectedDigitAfterPrefix(at: Text.Position)
    }
}
