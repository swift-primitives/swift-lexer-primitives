extension Lexer.Pull {

    public protocol Tokens {

        associatedtype Kind: Hashable & Sendable

        associatedtype Error: Swift.Error

        associatedtype Scratch = ()

        static func delta(for kind: Kind) -> Int

        static func initial() -> Scratch

        static func skip(whitespace scanner: inout Lexer.Scanner)

        static func next(
            scanner: inout Lexer.Scanner,
            depth: inout Int,
            limit: Int
        ) throws(Error) -> Kind?

        static func skip(
            value scanner: inout Lexer.Scanner,
            depth: inout Int,
            limit: Int
        ) throws(Error)
    }
}

extension Lexer.Pull.Tokens where Scratch == () {

    @inlinable
    public static func initial() { () }
}
