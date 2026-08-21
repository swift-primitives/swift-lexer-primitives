extension Lexer {

    public struct Position: Equatable, Hashable, Sendable {

        public let offset: Text.Position

        public let location: Text.Location

        @inlinable
        public init(offset: Text.Position, location: Text.Location) {
            self.offset = offset
            self.location = location
        }
    }
}

extension Lexer.Position: CustomStringConvertible {

    @inlinable
    public var description: Swift.String {
        "line \(location.line), column \(location.column) (byte \(Int(bitPattern: offset)))"
    }
}
