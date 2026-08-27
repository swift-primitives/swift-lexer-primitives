public import Lexer

extension Lexer.Position: CustomStringConvertible {

    @inlinable
    public var description: Swift.String {
        "line \(location.line), column \(location.column) (byte \(Int(bitPattern: offset)))"
    }
}
