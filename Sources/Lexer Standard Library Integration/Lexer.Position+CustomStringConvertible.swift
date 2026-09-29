public import Lexer
public import Ordinal
public import Tagged
public import Text

extension Lexer.Position: CustomStringConvertible {

    @inlinable
    public var description: Swift.String {
        "line \(location.line), column \(location.column) (byte \(Int(bitPattern: offset)))"
    }
}
