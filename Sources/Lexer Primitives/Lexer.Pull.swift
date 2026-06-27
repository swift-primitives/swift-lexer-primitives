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

extension Lexer {
    /// Namespace for pull-mode structural-event machinery.
    ///
    /// `Lexer.Pull` collects the substrate-shared types that surfaced
    /// inside `swift-rfc-8259` during the streaming-deserialize arc and
    /// were pulled to L1 under the [RES-018] 2026-05-14 amendment
    /// (case (c) — layer-agnostic primitive surfacing inside an L2
    /// package; pull-down is the architecturally mandated default).
    ///
    /// The cohort:
    ///
    /// - ``Lexer/Pull/Stream`` — generic structural-event cursor over a
    ///   borrowed `Swift.Span<Byte>`. `~Copyable & ~Escapable` per the
    ///   institute byte-cursor discipline.
    /// - ``Lexer/Pull/Tokens`` — witness protocol describing a single
    ///   format's token vocabulary, error type, depth semantics, and
    ///   per-byte dispatch.
    /// - ``Lexer/Pull/Assemble`` — generic event-to-value assembler with
    ///   a FAST/SLOW gate.
    /// - ``Lexer/Pull/Assemble/Strategy`` — witness protocol describing
    ///   how a format assembles per-kind tokens into its value
    ///   representation.
    ///
    /// Format-specific specialisations (e.g., `RFC_8259.Pull.Tokens`,
    /// `RFC_8259.Pull.Assemble`) live in the format's own L2 package
    /// and plug into the L1 cohort via the witness protocols.
    public enum Pull {}
}
