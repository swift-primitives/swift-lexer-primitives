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

extension Lexer.Pull {
    /// A witness describing how to pull structural events from a byte
    /// stream for a single concrete format.
    ///
    /// Each conforming format (JSON, XML, YAML, CBOR, MessagePack,
    /// Plist, …) supplies its own byte-rules and token vocabulary; the
    /// generic ``Lexer/Pull/Stream`` operates over this witness and
    /// owns the substrate-shared machinery (lifecycle, depth tracking,
    /// fast-path delegation).
    ///
    /// ## What the witness owns (format-specific)
    ///
    /// - The `Kind` enum: the format's structural-token vocabulary
    ///   (`.objectStart`, `.string`, `.colon`, …).
    /// - The `Error` type: format-specific diagnostics.
    /// - Whitespace classification (`skip(whitespace:)`).
    /// - Per-byte token dispatch (`next(scanner:depth:limit:)`).
    /// - Depth-delta classification (`delta(for:)`).
    /// - Per-kind value-skip (`skip(value:depth:limit:)`).
    ///
    /// ## Tree-shape assumption
    ///
    /// The substrate-shared depth counter assumes linear depth
    /// tracking with a maximum bound. This fits tree-shaped formats
    /// (JSON, XML, MessagePack, CBOR-without-tags, TOML, Plist).
    /// Graph-shaped formats with anchor/alias indirection (YAML
    /// anchors, IPLD/CBOR tags) may require additional state at the
    /// witness layer; the substrate-shared depth field remains
    /// useful but is not the whole story for such formats.
    public protocol Tokens {
        /// The format's structural-token kind enum.
        associatedtype Kind: Equatable & Hashable & Sendable

        /// The format's error type for token-level failures.
        associatedtype Error: Swift.Error

        /// Per-stream payload-decode scratch state.
        ///
        /// Text-bearing formats with escape sequences (JSON's `\uXXXX`,
        /// XML CDATA, YAML quoted scalars, …) typically declare this
        /// as `[UInt8]` and use it to amortise allocation across
        /// payload decodes within a single parse. Formats with no
        /// payload buffer needs (CBOR, MessagePack, Plist binary)
        /// accept the unit-type default and pay zero storage.
        associatedtype Scratch = ()

        /// Returns the depth change implied by a token kind:
        /// `+1` for container-open tokens, `-1` for container-close
        /// tokens, `0` otherwise.
        static func delta(for kind: Kind) -> Int

        /// Produces the initial scratch state for a fresh stream.
        ///
        /// Default impl available when `Scratch == ()`.
        static func initial() -> Scratch

        /// Advance the scanner past format-defined whitespace.
        ///
        /// Called from ``Lexer/Pull/Stream/peek()`` and the dispatch
        /// heads of `next()` / `skip()`. The witness defines which
        /// bytes count as whitespace — JSON admits 0x20 / 0x09 / 0x0A
        /// / 0x0D per RFC 8259 §2; other formats may differ.
        static func skip(whitespace scanner: inout Lexer.Scanner)

        /// Read the next structural token from the scanner, advancing
        /// the cursor past it (and updating `depth` for container
        /// opens/closes against `limit`).
        ///
        /// Returns `nil` at end of input; otherwise returns the token
        /// kind. The body skips leading whitespace, peeks the next
        /// byte, dispatches to the format-specific lex method, and
        /// updates depth via ``delta(for:)``.
        static func next(
            scanner: inout Lexer.Scanner,
            depth: inout Int,
            limit: Int
        ) throws(Error) -> Kind?

        /// Skip a complete value at the current cursor — the byte
        /// after `skip(whitespace:)` MUST start a value. Recurses for
        /// nested containers; depth is managed by the caller's
        /// generic stream as a shared field.
        ///
        /// The witness implements per-format value-skip logic: which
        /// byte starts which kind, how to skip strings (escape rules),
        /// numbers (digit/sign/exponent rules), literals (`null`/
        /// `true`/`false`), and how to delimit container bodies.
        static func skip(
            value scanner: inout Lexer.Scanner,
            depth: inout Int,
            limit: Int
        ) throws(Error)
    }
}

extension Lexer.Pull.Tokens where Scratch == () {
    /// Default `initial()` for witnesses whose `Scratch` is the unit
    /// type — no payload buffer needed.
    @inlinable
    public static func initial() { () }
}
