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
    /// Swift-specific character classification predicates for the Primitives
    /// Swift subset.
    ///
    /// These predicates build on ``ASCII/Classification`` (generic ASCII rules)
    /// and add language-specific rules for Swift identifiers, operators, and
    /// whitespace categories.
    ///
    /// ## Scope
    ///
    /// Only the ASCII subset of Swift's identifier and operator rules.
    /// Full Unicode identifier support (emoji, non-Latin scripts) is a
    /// higher-layer concern.
    public enum Classify {

        // MARK: - Identifiers

        /// Whether `byte` can start a Swift identifier (ASCII subset).
        ///
        /// Identifier start: `[a-zA-Z_]`.
        @inlinable
        public static func isIdentifierStart(_ byte: UInt8) -> Bool {
            ASCII.Classification.isLetter(byte) || byte == 0x5F // '_'
        }

        /// Whether `byte` can continue a Swift identifier (ASCII subset).
        ///
        /// Identifier continuation: `[a-zA-Z0-9_]`.
        @inlinable
        public static func isIdentifierContinuation(_ byte: UInt8) -> Bool {
            ASCII.Classification.isAlphanumeric(byte) || byte == 0x5F // '_'
        }

        // MARK: - Operators

        /// Whether `byte` can start a Swift operator.
        ///
        /// Operator head characters: `/ = - + ! * % < > & | ^ ~ ?`.
        @inlinable
        public static func isOperatorStart(_ byte: UInt8) -> Bool {
            switch byte {
            case 0x2F, // '/'
                 0x3D, // '='
                 0x2D, // '-'
                 0x2B, // '+'
                 0x21, // '!'
                 0x2A, // '*'
                 0x25, // '%'
                 0x3C, // '<'
                 0x3E, // '>'
                 0x26, // '&'
                 0x7C, // '|'
                 0x5E, // '^'
                 0x7E, // '~'
                 0x3F: // '?'
                return true
            default:
                return false
            }
        }

        /// Whether `byte` can continue a Swift operator.
        ///
        /// Operator continuation includes the same set as operator start,
        /// plus `.` (which can appear in multi-character operators like `..<`).
        @inlinable
        public static func isOperatorContinuation(_ byte: UInt8) -> Bool {
            isOperatorStart(byte) || byte == 0x2E // '.'
        }

        // MARK: - Whitespace

        /// Whether `byte` is horizontal whitespace (space or tab).
        ///
        /// Horizontal whitespace is trivia that does not terminate a line.
        /// Used to distinguish trailing trivia (horizontal only) from leading
        /// trivia (which includes vertical whitespace).
        @inlinable
        public static func isHorizontalWhitespace(_ byte: UInt8) -> Bool {
            byte == 0x20 || byte == 0x09 // ' ' or '\t'
        }

        /// Whether `byte` starts a newline sequence.
        ///
        /// Newline characters: `\n` (0x0A) and `\r` (0x0D). The sequence
        /// `\r\n` is treated as a single newline by the scanner.
        @inlinable
        public static func isNewline(_ byte: UInt8) -> Bool {
            byte == 0x0A || byte == 0x0D
        }

        // MARK: - Numbers

        /// Whether `byte` is a decimal digit (`0`-`9`).
        @inlinable
        public static func isDecimalDigit(_ byte: UInt8) -> Bool {
            ASCII.Classification.isDigit(byte)
        }

        /// Whether `byte` is a hexadecimal digit (`0`-`9`, `a`-`f`, `A`-`F`).
        @inlinable
        public static func isHexDigit(_ byte: UInt8) -> Bool {
            ASCII.Classification.isHexDigit(byte)
        }

        /// Whether `byte` is a binary digit (`0` or `1`).
        @inlinable
        public static func isBinaryDigit(_ byte: UInt8) -> Bool {
            byte == 0x30 || byte == 0x31 // '0' or '1'
        }

        /// Whether `byte` is an octal digit (`0`-`7`).
        @inlinable
        public static func isOctalDigit(_ byte: UInt8) -> Bool {
            byte >= 0x30 && byte <= 0x37 // '0'...'7'
        }
    }
}
