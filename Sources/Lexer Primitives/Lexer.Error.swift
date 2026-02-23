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
    /// A diagnostic produced during lexical analysis.
    ///
    /// The scanner always makes progress — it never throws or halts. Instead,
    /// error conditions produce lexemes (often with ``Token/Kind-swift.enum/unknown``
    /// kind) and may record diagnostics for later reporting.
    ///
    /// Each error case carries the ``Text/Position`` where the error was
    /// detected, enabling precise diagnostic reporting.
    public enum Error: Swift.Error, Sendable, Equatable, Hashable {
        /// An unrecognized byte that does not start any valid token.
        case invalidCharacter(at: Text.Position)

        /// A `/*` block comment with no matching `*/`.
        case unterminatedBlockComment(at: Text.Position)

        /// A string literal with no closing delimiter.
        case unterminatedStringLiteral(at: Text.Position)

        /// An invalid escape sequence within a string literal (e.g., `\z`).
        case invalidEscapeSequence(at: Text.Position)

        /// A number literal prefix (`0x`, `0b`, `0o`) with no digits following.
        case expectedDigitAfterPrefix(at: Text.Position)
    }
}
