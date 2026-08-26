extension Lexer {

    public enum Trivia: Sendable, Equatable, Hashable {

        case space(Text.Count)

        case tab(Text.Count)

        case newline

        case carriageReturn

        case carriageReturnLineFeed

        case lineComment(Text.Range)

        case blockComment(Text.Range)
    }
}
