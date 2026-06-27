// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-lexer-primitives open source project
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp and the swift-lexer-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

extension Lexer.Pull.Assemble {
    /// A witness describing how a format assembles its tokens into a
    /// value of the format's value type.
    ///
    /// Two operations:
    ///
    /// - ``consume(bytes:limit:)`` — the wholesale fast-path: given
    ///   the entire input as a contiguous span and the depth limit,
    ///   produce the value directly without walking events. Used by
    ///   ``Lexer/Pull/Assemble/from(_:strategy:)`` when the event
    ///   stream is still pristine (the §4.3-style short-circuit).
    /// - ``build(events:)`` — the slow-path: walk the event stream
    ///   from the current cursor and build the value event-by-event.
    ///   Used when the stream has already been touched.
    ///
    /// Formats without a separate wholesale parser may implement
    /// ``consume(bytes:limit:)`` by constructing a fresh stream from
    /// `bytes` and delegating to ``build(events:)``.
    public protocol Strategy {
        /// The value type this strategy produces.
        associatedtype Value

        /// The format's token witness.
        associatedtype Tokens: Lexer.Pull.Tokens

        /// Wholesale fast-path: produce a value from the entire byte
        /// span without walking events.
        static func consume(
            bytes: Swift.Span<Byte>,
            limit: Int
        ) throws(Tokens.Error) -> Value

        /// Slow-path: build the value by walking events from the
        /// current cursor.
        static func build(
            events: inout Lexer.Pull.Stream<Tokens>
        ) throws(Tokens.Error) -> Value
    }
}
