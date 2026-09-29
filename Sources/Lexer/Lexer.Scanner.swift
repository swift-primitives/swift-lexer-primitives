public import Difference
public import Ordinal
public import Byte
public import Span
public import Text

extension Lexer {

    @frozen
    @safe
    public struct Scanner: ~Copyable, ~Escapable {
        @usableFromInline
        internal var offset: Int

        @usableFromInline
        internal let source: Swift.Span<Byte>

        @usableFromInline
        internal var hasEmittedEndOfFile: Bool

        @usableFromInline
        internal var tracker: Text.Location.Tracker

        @inlinable
        @_lifetime(borrow source)
        public init(_ source: borrowing Swift.Span<Byte>) {
            self.source = copy source

            self.offset = 0
            self.hasEmittedEndOfFile = false
            self.tracker = Text.Location.Tracker()
        }
    }
}

extension Lexer.Scanner {

    @inlinable
    public var position: Text.Position { Text.Position(_unchecked: Ordinal(UInt(offset))) }

    @inlinable
    public var location: Text.Location { tracker.location(at: position) }

    @inlinable
    public func location(at position: Text.Position) -> Text.Location {
        guard let end = Int(exactly: position.underlying.rawValue), end <= source.count else {
            preconditionFailure("Scanner location is outside the source")
        }
        var tracker = Text.Location.Tracker()
        for index in 0..<end {
            if source[index].bitPattern == 0x0A {
                tracker.newline(at: Text.Position(_unchecked: Ordinal(UInt(index))))
            }
        }
        return tracker.location(at: position)
    }

    @inlinable
    public var isAtEnd: Bool { offset == source.count }

    @inlinable
    public func peek() -> Byte? { isAtEnd ? nil : source[offset] }

    @inlinable
    public func peek(at distance: Text.Count) -> Byte? {
        guard let distance = Int(exactly: distance.underlying.rawValue),
              distance < source.count - offset else { return nil }
        return source[offset + distance]
    }

    @_disfavoredOverload
    @inlinable
    public func peek<X, Failure: Swift.Error>(validating validate: (Byte) throws(Failure) -> X) -> X? {
        guard let byte = peek() else { return nil }
        do throws(Failure) {
            return try validate(byte)
        } catch {
            return nil
        }
    }

    @_disfavoredOverload
    @inlinable
    public func peek<X, Failure: Swift.Error>(at offset: Text.Count, validating validate: (Byte) throws(Failure) -> X) -> X? {
        guard let byte = peek(at: offset) else { return nil }
        do throws(Failure) {
            return try validate(byte)
        } catch {
            return nil
        }
    }

    @inlinable
    @_lifetime(self: copy self)
    public mutating func advance() {
        precondition(offset < source.count, "Cannot advance past the scanner source")
        offset += 1
    }

    @inlinable
    @_lifetime(self: copy self)
    public mutating func advance(by count: Text.Count) {
        guard let count = Int(exactly: count.underlying.rawValue), count <= source.count - offset else {
            preconditionFailure("Scanner advance is outside the source")
        }
        offset += count
    }

    @inlinable
    @_lifetime(self: copy self)
    public mutating func consume() -> Byte {
        precondition(offset < source.count, "Cannot consume past the scanner source")
        let byte = source[offset]
        offset += 1
        return byte
    }

    @inlinable
    @_lifetime(self: copy self)
    public mutating func newline(at position: Text.Position) {
        tracker.newline(at: position)
    }
}

extension Lexer.Scanner {
    @usableFromInline
    internal var cursor: Text.Position {
        @inlinable

        get { position }
        @inlinable
        @_lifetime(self: copy self)
        set {
            guard let value = Int(exactly: newValue.underlying.rawValue), value <= source.count else {
                preconditionFailure("Scanner checkpoint is outside the source")
            }
            offset = value
        }
    }
}

extension Lexer.Scanner {

    @inlinable
    @inline(__always)
    package func contains(_ position: Text.Position) -> Bool {
        guard let index = Int(exactly: position.underlying.rawValue) else { return false }
        return index < source.count
    }

    @inlinable
    @inline(__always)
    package func byte(at position: Text.Position) -> Byte {
        guard let index = Int(exactly: position.underlying.rawValue), index < source.count else {
            preconditionFailure("Scanner position is outside the source")
        }
        return source[index]
    }

    @inlinable
    @inline(__always)
    @_lifetime(borrow self)
    package func extract(
        from start: Text.Position,
        to end: Text.Position
    ) -> Swift.Span<Byte> {
        guard let lower = Int(exactly: start.underlying.rawValue),
              let upper = Int(exactly: end.underlying.rawValue),
              lower <= upper, upper <= source.count else {
            preconditionFailure("Scanner range is outside the source")
        }
        return source.extracting(lower..<upper)
    }

    @inlinable
    @inline(__always)
    package func distance(
        from start: Text.Position,
        to end: Text.Position
    ) -> Text.Count {

        return (end - start).magnitude.map { $0.value }
    }
}
