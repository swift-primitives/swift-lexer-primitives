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

import Lexer_Primitives
import Testing

/// Minimal format witness used to validate the L1 ``Lexer/Pull/Stream``
/// cohort.
///
/// The format is a balanced-bracket grammar: `[` opens a
/// container, `]` closes it. Whitespace bytes (0x20, 0x09, 0x0A, 0x0D)
/// are skipped between tokens. No payload, no escapes — the smallest
/// surface that exercises the generic substrate.
enum BracketTokens: Lexer.Pull.Tokens {}

extension BracketTokens {
    enum Kind: Equatable, Hashable, Sendable {
        case open
        case close
    }

    enum Error: Swift.Error, Equatable {
        case unexpected(Byte)
        case unbalanced
    }

    static func delta(for kind: Kind) -> Int {
        switch kind {
        case .open: return 1
        case .close: return -1
        }
    }

    static func skip(whitespace scanner: inout Lexer.Scanner) {
        while let byte = scanner.peek() {
            switch byte {
            case 0x20, 0x09, 0x0A, 0x0D:
                scanner.advance()

            default:
                return
            }
        }
    }

    static func next(
        scanner: inout Lexer.Scanner,
        depth: inout Int,
        limit: Int
    ) throws(Error) -> Kind? {
        skip(whitespace: &scanner)
        guard let byte = scanner.peek() else { return nil }
        switch byte {
        case 0x5B:  // '['
            depth &+= 1
            if depth > limit { throw .unbalanced }
            scanner.advance()
            return .open

        case 0x5D:  // ']'
            scanner.advance()
            depth &-= 1
            return .close

        default:
            throw .unexpected(byte)
        }
    }

    static func skip(
        value scanner: inout Lexer.Scanner,
        depth: inout Int,
        limit: Int
    ) throws(Error) {
        // For brackets, a "value" is a balanced container; consume
        // tokens until depth returns to its entry value.
        let entryDepth = depth
        repeat {
            guard try next(scanner: &scanner, depth: &depth, limit: limit) != nil else {
                throw .unbalanced
            }
        } while depth > entryDepth
    }
}

extension Lexer.Pull {
    @Suite("Lexer.Pull")
    struct Test {

    private func withSpan<R>(
        _ source: String,
        _ body: (borrowing Swift.Span<Byte>) throws -> R
    ) rethrows -> R {
        let bytes: [Byte] = source.utf8.map(Byte.init)
        return try bytes.withUnsafeBufferPointer { buffer in
            let span = unsafe Span(_unsafeElements: buffer)
            return try body(span)
        }
    }

    @Test
    func `Empty input yields nil immediately`() throws {
        try withSpan("") { span in
            var stream = Lexer.Pull.Stream<BracketTokens>(span)
            let first = try stream.next()
            #expect(first == nil)
        }
    }

    @Test
    func `Single empty container yields open then close`() throws {
        try withSpan("[]") { span in
            var stream = Lexer.Pull.Stream<BracketTokens>(span)
            let a = try stream.next()
            #expect(a == .open)
            let b = try stream.next()
            #expect(b == .close)
            let c = try stream.next()
            #expect(c == nil)
        }
    }

    @Test
    func `Whitespace is skipped between tokens`() throws {
        try withSpan("  [ \n\t ] ") { span in
            var stream = Lexer.Pull.Stream<BracketTokens>(span)
            let a = try stream.next()
            #expect(a == .open)
            let b = try stream.next()
            #expect(b == .close)
            let c = try stream.next()
            #expect(c == nil)
        }
    }

    @Test
    func `Nested containers update depth correctly`() throws {
        try withSpan("[[[]]]") { span in
            var stream = Lexer.Pull.Stream<BracketTokens>(span)
            for _ in 0..<3 {
                let kind = try stream.next()
                #expect(kind == .open)
            }
            for _ in 0..<3 {
                let kind = try stream.next()
                #expect(kind == .close)
            }
            let tail = try stream.next()
            #expect(tail == nil)
        }
    }

    @Test
    func `Depth limit is enforced`() throws {
        try withSpan("[[[") { span in
            var stream = Lexer.Pull.Stream<BracketTokens>(span, limit: 2)
            let a = try stream.next()
            #expect(a == .open)
            let b = try stream.next()
            #expect(b == .open)
            #expect(throws: BracketTokens.Error.unbalanced) {
                try stream.next()
            }
        }
    }

    @Test
    func `peek returns next significant byte without consuming`() throws {
        try withSpan("  [") { span in
            var stream = Lexer.Pull.Stream<BracketTokens>(span)
            #expect(stream.peek() == 0x5B)
            #expect(stream.peek() == 0x5B)  // idempotent
            let kind = try stream.next()
            #expect(kind == .open)
        }
    }

    @Test
    func `isPristine clears on first next()`() throws {
        try withSpan("[]") { span in
            var stream = Lexer.Pull.Stream<BracketTokens>(span)
            #expect(stream.isPristine == true)
            _ = try stream.next()
            #expect(stream.isPristine == false)
        }
    }

    @Test
    func `position reports current byte offset`() throws {
        try withSpan("  []") { span in
            var stream = Lexer.Pull.Stream<BracketTokens>(span)
            _ = try stream.next()  // advances past whitespace + '['
            #expect(Int(bitPattern: stream.position) == 3)  // cursor sits at ']'
        }
    }

    @Test
    func `skip on balanced nested container consumes the entire value`() throws {
        try withSpan("[[[]]]") { span in
            var stream = Lexer.Pull.Stream<BracketTokens>(span)
            try stream.skip()  // consume one complete value at cursor
            let tail = try stream.next()
            #expect(tail == nil)  // entire input consumed
        }
    }
    }
}

/// Minimal strategy witness exercising the FAST/SLOW gate.
enum BracketCount: Lexer.Pull.Assemble.Strategy {}

extension BracketCount {
    typealias Tokens = BracketTokens
    typealias Value = Int

    static func consume(
        bytes: Swift.Span<Byte>,
        limit: Int
    ) throws(BracketTokens.Error) -> Int {
        // Wholesale fast-path: count opens by direct byte scan.
        var count = 0
        for i in 0..<bytes.count {
            if bytes[i] == 0x5B { count &+= 1 }
        }
        return count
    }

    static func build(
        events: inout Lexer.Pull.Stream<BracketTokens>
    ) throws(BracketTokens.Error) -> Int {
        // Slow-path: count opens by walking events.
        var count = 0
        while let kind = try events.next() {
            if kind == .open { count &+= 1 }
        }
        return count
    }
}

extension Lexer.Pull.Assemble {
    @Suite("Lexer.Pull.Assemble")
    struct Test {

    private func withSpan<R>(
        _ source: String,
        _ body: (borrowing Swift.Span<Byte>) throws -> R
    ) rethrows -> R {
        let bytes: [Byte] = source.utf8.map(Byte.init)
        return try bytes.withUnsafeBufferPointer { buffer in
            let span = unsafe Span(_unsafeElements: buffer)
            return try body(span)
        }
    }

    @Test
    func `FAST path fires when stream is pristine`() throws {
        try withSpan("[[[]]]") { span in
            var stream = Lexer.Pull.Stream<BracketTokens>(span)
            #expect(stream.isPristine == true)
            let count = try Lexer.Pull.Assemble.from(&stream, strategy: BracketCount.self)
            #expect(count == 3)
            // Fast-path marks the stream consumed.
            let tail = try stream.next()
            #expect(tail == nil)
        }
    }

    @Test
    func `SLOW path fires when stream is no longer pristine`() throws {
        try withSpan("[[[]]]") { span in
            var stream = Lexer.Pull.Stream<BracketTokens>(span)
            _ = try stream.next()  // pristine cleared; depth=1
            // Slow path: count remaining opens (2 more, since one already pulled).
            let count = try Lexer.Pull.Assemble.from(&stream, strategy: BracketCount.self)
            #expect(count == 2)
        }
    }
    }
}
