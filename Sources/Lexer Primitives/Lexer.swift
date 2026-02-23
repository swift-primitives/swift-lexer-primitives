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

/// Namespace for lexical analysis types and operations.
///
/// The lexer bridges source text (byte sequences) to token streams. It sits
/// between token-primitives (vocabulary) and parser-primitives (combinators)
/// in the compiler infrastructure.
///
/// ## Types
///
/// - ``Lexer/Lexeme``: A token with trivia metadata — what the lexer produces.
/// - ``Lexer/Trivia``: Structured classification of non-token content.
/// - ``Lexer/Scanner``: Concrete lexer that scans bytes into lexemes.
/// - ``Lexer/Classify``: Swift-specific character classification predicates.
/// - ``Lexer/Error``: Diagnostic for lexing errors.
public enum Lexer {}
