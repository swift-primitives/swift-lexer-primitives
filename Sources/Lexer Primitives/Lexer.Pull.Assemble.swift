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
    /// Generic FAST/SLOW gate for assembling a value from a
    /// ``Lexer/Pull/Stream``.
    ///
    /// The gate logic is substrate-shared — "if the stream hasn't
    /// moved, fast-path via wholesale-parse; else slow-path via
    /// event-rebuild" applies to any pull-event structural format.
    /// The format-specific work (which value type to build, which
    /// wholesale parser to call, how to walk per-kind) lives on the
    /// ``Lexer/Pull/Assemble/Strategy`` witness.
    public enum Assemble {}
}

extension Lexer.Pull.Assemble {
    /// FAST/SLOW gate: if the stream is pristine (cursor at position 0,
    /// nothing consumed), invoke the strategy's wholesale ``consume``;
    /// otherwise invoke its ``build`` to walk events.
    ///
    /// Format-agnostic — the strategy supplies the value type, the
    /// wholesale parser, and the event-walking body.
    @inlinable
    public static func from<S: Strategy>(
        _ events: inout Lexer.Pull.Stream<S.Tokens>,
        strategy: S.Type
    ) throws(S.Tokens.Error) -> S.Value {
        guard events.isPristine else {
            return try S.build(events: &events)
        }
        return try events.consume(via: S.consume(bytes:limit:))
    }
}
