extension Lexer {

    public enum Classify {}
}

extension Lexer.Classify {

    @inlinable
    public static func isIdentifierStart(_ byte: Byte) -> Bool {
        ASCII.Classification.isLetter(byte.underlying) || byte == 0x5F
    }

    @inlinable
    public static func isIdentifierContinuation(_ byte: Byte) -> Bool {
        ASCII.Classification.isAlphanumeric(byte.underlying) || byte == 0x5F
    }

    @inlinable
    public static func isOperatorStart(_ byte: Byte) -> Bool {
        switch byte {
        case 0x2F,
            0x3D,
            0x2D,
            0x2B,
            0x21,
            0x2A,
            0x25,
            0x3C,
            0x3E,
            0x26,
            0x7C,
            0x5E,
            0x7E,
            0x3F:
            return true

        default:
            return false
        }
    }

    @inlinable
    public static func isOperatorContinuation(_ byte: Byte) -> Bool {
        isOperatorStart(byte) || byte == 0x2E
    }

    @inlinable
    public static func isHorizontalWhitespace(_ byte: Byte) -> Bool {
        byte == 0x20 || byte == 0x09
    }

    @inlinable
    public static func isNewline(_ byte: Byte) -> Bool {
        byte == 0x0A || byte == 0x0D
    }

    @inlinable
    public static func isDecimalDigit(_ byte: Byte) -> Bool {
        ASCII.Classification.isDigit(byte.underlying)
    }

    @inlinable
    public static func isHexDigit(_ byte: Byte) -> Bool {
        ASCII.Classification.isHexDigit(byte.underlying)
    }

    @inlinable
    public static func isBinaryDigit(_ byte: Byte) -> Bool {
        byte == 0x30 || byte == 0x31
    }

    @inlinable
    public static func isOctalDigit(_ byte: Byte) -> Bool {
        byte >= 0x30 && byte <= 0x37
    }
}
