public import Byte
public import Cursor_Primitive
import Cursor
public import Memory_Cursor
import Memory_Primitive
public import Span_Protocol

extension Lexer {

    @frozen
    @safe
    public struct Scanner: ~Copyable, ~Escapable {
        @usableFromInline
        internal var inner: Cursor<Text>

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

            self.inner = Cursor<Text>(copy source)
            self.hasEmittedEndOfFile = false
            self.tracker = Text.Location.Tracker()
        }
    }
}

extension Lexer.Scanner {

    @inlinable
    public var position: Text.Position { inner.position }

    @inlinable
    public var location: Text.Location { tracker.location(at: inner.position) }

    @inlinable
    public func location(at position: Text.Position) -> Text.Location {
        var tracker = Text.Location.Tracker()
        var i: Text.Position = .zero
        while i < position {
            if byte(at: i) == 0x0A {
                tracker.newline(at: i)
            }
            i += .one
        }
        return tracker.location(at: position)
    }

    @inlinable
    public var isAtEnd: Bool { inner.isAtEnd }

    @inlinable
    public func peek() -> Byte? { inner.peek() }

    @inlinable
    public func peek(at offset: Text.Count) -> Byte? { inner.peek(at: offset) }

    @_disfavoredOverload
    @inlinable
    public func peek<X: Byte.`Protocol`>() -> X? {
        guard let byte = inner.peek() else { return nil }
        do throws(X.Error) {
            return try X(byte)
        } catch {
            return nil
        }
    }

    @_disfavoredOverload
    @inlinable
    public func peek<X: Byte.`Protocol`>(at offset: Text.Count) -> X? {
        guard let byte = inner.peek(at: offset) else { return nil }
        do throws(X.Error) {
            return try X(byte)
        } catch {
            return nil
        }
    }

    @inlinable
    @_lifetime(self: copy self)
    public mutating func advance() { inner.advance() }

    @inlinable
    @_lifetime(self: copy self)
    public mutating func advance(by count: Text.Count) { inner.advance(by: count) }

    @inlinable
    @_lifetime(self: copy self)
    public mutating func consume() -> Byte { inner.consume() }

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

        get { inner.position }
        @inlinable
        @_lifetime(self: copy self)
        set { inner.seek(to: newValue) }
    }
}

extension Lexer.Scanner {

    @inlinable
    @inline(__always)
    package func contains(_ position: Text.Position) -> Bool {
        Int(bitPattern: position) < source.count
    }

    @inlinable
    @inline(__always)
    package func byte(at position: Text.Position) -> Byte {
        source[Int(bitPattern: position)]
    }

    @inlinable
    @inline(__always)
    @_lifetime(borrow self)
    package func extract(
        from start: Text.Position,
        to end: Text.Position
    ) -> Swift.Span<Byte> {
        source.extracting(
            Int(bitPattern: start)..<Int(bitPattern: end)
        )
    }

    @inlinable
    @inline(__always)
    package func distance(
        from start: Text.Position,
        to end: Text.Position
    ) -> Text.Count {

        do throws(Affine.Discrete.Vector.Error) {
            return try (end - start).magnitude
        } catch {
            return .zero
        }
    }
}
