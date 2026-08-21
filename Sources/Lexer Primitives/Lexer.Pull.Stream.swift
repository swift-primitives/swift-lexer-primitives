extension Lexer.Pull {

    @safe
    public struct Stream<Tokens: Lexer.Pull.Tokens>: ~Copyable, ~Escapable {

        public var scanner: Lexer.Scanner

        @usableFromInline
        internal var depth: Int

        @usableFromInline
        internal let limit: Int

        @usableFromInline
        internal var pristine: Bool

        @usableFromInline
        internal var consumed: Bool

        @usableFromInline
        internal let bytes: Swift.Span<Byte>

        public var scratch: Tokens.Scratch

        @inlinable
        @_lifetime(borrow bytes)
        public init(_ bytes: borrowing Swift.Span<Byte>, limit: Int = 512) {
            self.scanner = Lexer.Scanner(bytes)
            self.bytes = copy bytes
            self.depth = 0
            self.limit = limit
            self.pristine = true
            self.consumed = false
            self.scratch = Tokens.initial()
        }
    }
}

extension Lexer.Pull.Stream {

    @inlinable
    public var isPristine: Bool { pristine }

    @inlinable
    public var isConsumed: Bool { consumed }

    @inlinable
    @_lifetime(self: copy self)
    public mutating func touch() {
        pristine = false
    }
}

extension Lexer.Pull.Stream {

    @inlinable
    public var position: Text.Position { scanner.position }

    @inlinable
    public func position(at cursor: Text.Position) -> Lexer.Position {
        Lexer.Position(offset: cursor, location: scanner.location(at: cursor))
    }
}

extension Lexer.Pull.Stream {

    @inlinable
    @_lifetime(self: copy self)
    public mutating func peek() -> Byte? {
        Tokens.skip(whitespace: &scanner)
        return scanner.peek()
    }

    @inlinable
    @_lifetime(self: copy self)
    public mutating func next() throws(Tokens.Error) -> Tokens.Kind? {
        pristine = false
        guard !consumed else { return nil }
        return try Tokens.next(
            scanner: &scanner,
            depth: &depth,
            limit: limit
        )
    }

    @inlinable
    @_lifetime(self: copy self)
    public mutating func skip() throws(Tokens.Error) {
        pristine = false
        try Tokens.skip(
            value: &scanner,
            depth: &depth,
            limit: limit
        )
    }
}

extension Lexer.Pull.Stream {

    @inlinable
    @_lifetime(self: copy self)
    public mutating func consume<V, E: Swift.Error>(
        via parse: (Swift.Span<Byte>, Int) throws(E) -> V
    ) throws(E) -> V {
        pristine = false
        let value = try parse(bytes, limit)
        consumed = true
        return value
    }
}
