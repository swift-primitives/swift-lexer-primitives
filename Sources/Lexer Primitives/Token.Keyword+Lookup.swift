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

// MARK: - Keyword Reverse Lookup

extension Token.Keyword {
    /// Creates a keyword from a UTF-8 byte sequence, if the bytes match a
    /// known Swift keyword.
    ///
    /// Uses a length-partitioned switch for efficient lookup. The outer switch
    /// dispatches on byte count; inner branches compare against keywords of
    /// that length. Since all 64 keywords have known lengths, this provides
    /// O(1) amortized lookup with zero allocation.
    ///
    /// ## Keyword Length Distribution
    ///
    /// | Length | Count | Keywords |
    /// |--------|-------|----------|
    /// | 2 | 5 | as, do, if, in, is |
    /// | 3 | 8 | any, for, get, let, nil, set, try, var |
    /// | 4 | 10 | case, each, else, enum, func, init, self, Self, some, true |
    /// | 5 | 11 | _read, break, catch, defer, false, guard, inout, throw, where, while, yield |
    /// | 6 | 9 | deinit, import, public, repeat, return, static, struct, switch, throws |
    /// | 7 | 5 | _modify, default, discard, package, private |
    /// | 8 | 6 | continue, indirect, internal, mutating, operator, protocol |
    /// | 9 | 5 | borrowing, consuming, extension, subscript, typealias |
    /// | 11 | 3 | fallthrough, fileprivate, nonmutating |
    /// | 14 | 1 | associatedtype |
    /// | 15 | 1 | precedencegroup |
    @inlinable
    public init?(_ utf8: UnsafeBufferPointer<UInt8>) {
        guard let base = unsafe utf8.baseAddress else { return nil }
        switch utf8.count {
        case 2: self.init(_length2: base)
        case 3: self.init(_length3: base)
        case 4: self.init(_length4: base)
        case 5: self.init(_length5: base)
        case 6: self.init(_length6: base)
        case 7: self.init(_length7: base)
        case 8: self.init(_length8: base)
        case 9: self.init(_length9: base)
        case 11: self.init(_length11: base)
        case 14: self.init(_length14: base)
        case 15: self.init(_length15: base)
        default: return nil
        }
    }

    /// Creates a keyword from a byte-typed UTF-8 buffer.
    ///
    /// Byte-domain overload covering the W2 cascade — callers holding
    /// `UnsafeBufferPointer<Byte>` (e.g., from `Swift.Span<Byte>` via
    /// `withUnsafeBufferPointer`) reach for this form without re-binding
    /// the memory at the call site. Byte is layout-equivalent to UInt8
    /// (`@frozen public struct Byte { public let underlying: UInt8 }`),
    /// so `withMemoryRebound` is the Swift-safe reinterpretation path.
    @inlinable
    public init?(_ utf8: UnsafeBufferPointer<Byte>) {
        guard let base = unsafe utf8.baseAddress else { return nil }
        let result: Token.Keyword? = unsafe base.withMemoryRebound(
            to: UInt8.self,
            capacity: utf8.count
        ) { ptr in
            Token.Keyword(unsafe UnsafeBufferPointer<UInt8>(start: ptr, count: utf8.count))
        }
        guard let result else { return nil }
        self = result
    }
}

// MARK: - Length-Partitioned Matching

extension Token.Keyword {
    /// Matches keywords of length 2: as, do, if, in, is.
    @inlinable
    init?(_length2 p: UnsafePointer<UInt8>) {
        switch (unsafe p[0], unsafe p[1]) {
        case (0x61, 0x73): self = .as  // "as"
        case (0x64, 0x6F): self = .do  // "do"
        case (0x69, 0x66): self = .if  // "if"
        case (0x69, 0x6E): self = .in  // "in"
        case (0x69, 0x73): self = .is  // "is"
        default: return nil
        }
    }

    /// Matches keywords of length 3: any, for, get, let, nil, set, try, var.
    @inlinable
    init?(_length3 p: UnsafePointer<UInt8>) {
        switch (unsafe p[0], unsafe p[1], unsafe p[2]) {
        case (0x61, 0x6E, 0x79): self = .any  // "any"
        case (0x66, 0x6F, 0x72): self = .for  // "for"
        case (0x67, 0x65, 0x74): self = .get  // "get"
        case (0x6C, 0x65, 0x74): self = .let  // "let"
        case (0x6E, 0x69, 0x6C): self = .nil  // "nil"
        case (0x73, 0x65, 0x74): self = .set  // "set"
        case (0x74, 0x72, 0x79): self = .try  // "try"
        case (0x76, 0x61, 0x72): self = .var  // "var"
        default: return nil
        }
    }

    /// Matches keywords of length 4: case, each, else, enum, func, init,
    /// self, Self, some, true.
    @inlinable
    init?(_length4 p: UnsafePointer<UInt8>) {
        switch unsafe p[0] {
        case 0x63:  // 'c'
            if unsafe _matches(p, 0x63, 0x61, 0x73, 0x65) {
                self = .case
                return
            }  // "case"
            return nil

        case 0x65:  // 'e'
            if unsafe _matches(p, 0x65, 0x61, 0x63, 0x68) {
                self = .each
                return
            }  // "each"
            if unsafe _matches(p, 0x65, 0x6C, 0x73, 0x65) {
                self = .else
                return
            }  // "else"
            if unsafe _matches(p, 0x65, 0x6E, 0x75, 0x6D) {
                self = .enum
                return
            }  // "enum"
            return nil

        case 0x66:  // 'f'
            if unsafe _matches(p, 0x66, 0x75, 0x6E, 0x63) {
                self = .func
                return
            }  // "func"
            return nil

        case 0x69:  // 'i'
            if unsafe _matches(p, 0x69, 0x6E, 0x69, 0x74) {
                self = .`init`
                return
            }  // "init"
            return nil

        case 0x73:  // 's'
            if unsafe _matches(p, 0x73, 0x65, 0x6C, 0x66) {
                self = .`self`
                return
            }  // "self"
            if unsafe _matches(p, 0x73, 0x6F, 0x6D, 0x65) {
                self = .some
                return
            }  // "some"
            return nil

        case 0x53:  // 'S'
            if unsafe _matches(p, 0x53, 0x65, 0x6C, 0x66) {
                self = .`Self`
                return
            }  // "Self"
            return nil

        case 0x74:  // 't'
            if unsafe _matches(p, 0x74, 0x72, 0x75, 0x65) {
                self = .`true`
                return
            }  // "true"
            return nil

        default:
            return nil
        }
    }

    /// Matches keywords of length 5: _read, break, catch, defer, false,
    /// guard, inout, throw, where, while, yield.
    @inlinable
    init?(_length5 p: UnsafePointer<UInt8>) {
        switch unsafe p[0] {
        case 0x5F:  // '_'
            if unsafe _matches5(p, 0x5F, 0x72, 0x65, 0x61, 0x64) {
                self = ._read
                return
            }  // "_read"
            return nil

        case 0x62:  // 'b'
            if unsafe _matches5(p, 0x62, 0x72, 0x65, 0x61, 0x6B) {
                self = .break
                return
            }  // "break"
            return nil

        case 0x63:  // 'c'
            if unsafe _matches5(p, 0x63, 0x61, 0x74, 0x63, 0x68) {
                self = .catch
                return
            }  // "catch"
            return nil

        case 0x64:  // 'd'
            if unsafe _matches5(p, 0x64, 0x65, 0x66, 0x65, 0x72) {
                self = .defer
                return
            }  // "defer"
            return nil

        case 0x66:  // 'f'
            if unsafe _matches5(p, 0x66, 0x61, 0x6C, 0x73, 0x65) {
                self = .`false`
                return
            }  // "false"
            return nil

        case 0x67:  // 'g'
            if unsafe _matches5(p, 0x67, 0x75, 0x61, 0x72, 0x64) {
                self = .guard
                return
            }  // "guard"
            return nil

        case 0x69:  // 'i'
            if unsafe _matches5(p, 0x69, 0x6E, 0x6F, 0x75, 0x74) {
                self = .inout
                return
            }  // "inout"
            return nil

        case 0x74:  // 't'
            if unsafe _matches5(p, 0x74, 0x68, 0x72, 0x6F, 0x77) {
                self = .throw
                return
            }  // "throw"
            return nil

        case 0x77:  // 'w'
            if unsafe _matches5(p, 0x77, 0x68, 0x65, 0x72, 0x65) {
                self = .where
                return
            }  // "where"
            if unsafe _matches5(p, 0x77, 0x68, 0x69, 0x6C, 0x65) {
                self = .while
                return
            }  // "while"
            return nil

        case 0x79:  // 'y'
            if unsafe _matches5(p, 0x79, 0x69, 0x65, 0x6C, 0x64) {
                self = .yield
                return
            }  // "yield"
            return nil

        default:
            return nil
        }
    }

    /// Matches keywords of length 6: deinit, import, public, repeat, return,
    /// static, struct, switch, throws.
    @inlinable
    init?(_length6 p: UnsafePointer<UInt8>) {
        switch unsafe p[0] {
        case 0x64:  // 'd'
            if unsafe _matchesTail5(p, 0x65, 0x69, 0x6E, 0x69, 0x74) {
                self = .deinit
                return
            }  // "deinit"
            return nil

        case 0x69:  // 'i'
            if unsafe _matchesTail5(p, 0x6D, 0x70, 0x6F, 0x72, 0x74) {
                self = .import
                return
            }  // "import"
            return nil

        case 0x70:  // 'p'
            if unsafe _matchesTail5(p, 0x75, 0x62, 0x6C, 0x69, 0x63) {
                self = .public
                return
            }  // "public"
            return nil

        case 0x72:  // 'r'
            if unsafe _matchesTail5(p, 0x65, 0x70, 0x65, 0x61, 0x74) {
                self = .repeat
                return
            }  // "repeat"
            if unsafe _matchesTail5(p, 0x65, 0x74, 0x75, 0x72, 0x6E) {
                self = .return
                return
            }  // "return"
            return nil

        case 0x73:  // 's'
            if unsafe _matchesTail5(p, 0x74, 0x61, 0x74, 0x69, 0x63) {
                self = .static
                return
            }  // "static"
            if unsafe _matchesTail5(p, 0x74, 0x72, 0x75, 0x63, 0x74) {
                self = .struct
                return
            }  // "struct"
            if unsafe _matchesTail5(p, 0x77, 0x69, 0x74, 0x63, 0x68) {
                self = .switch
                return
            }  // "switch"
            return nil

        case 0x74:  // 't'
            if unsafe _matchesTail5(p, 0x68, 0x72, 0x6F, 0x77, 0x73) {
                self = .throws
                return
            }  // "throws"
            return nil

        default:
            return nil
        }
    }

    /// Matches keywords of length 7: _modify, default, discard, package, private.
    @inlinable
    init?(_length7 p: UnsafePointer<UInt8>) {
        switch unsafe p[0] {
        case 0x5F:  // '_'
            if unsafe _matchesSuffix(p, count: 7, 0x5F, 0x6D, 0x6F, 0x64, 0x69, 0x66, 0x79) {
                self = ._modify
                return
            }  // "_modify"
            return nil

        case 0x64:  // 'd'
            if unsafe _matchesSuffix(p, count: 7, 0x64, 0x65, 0x66, 0x61, 0x75, 0x6C, 0x74) {
                self = .default
                return
            }  // "default"
            if unsafe _matchesSuffix(p, count: 7, 0x64, 0x69, 0x73, 0x63, 0x61, 0x72, 0x64) {
                self = .discard
                return
            }  // "discard"
            return nil

        case 0x70:  // 'p'
            if unsafe _matchesSuffix(p, count: 7, 0x70, 0x61, 0x63, 0x6B, 0x61, 0x67, 0x65) {
                self = .package
                return
            }  // "package"
            if unsafe _matchesSuffix(p, count: 7, 0x70, 0x72, 0x69, 0x76, 0x61, 0x74, 0x65) {
                self = .private
                return
            }  // "private"
            return nil

        default:
            return nil
        }
    }

    /// Matches keywords of length 8: continue, indirect, internal, mutating,
    /// operator, protocol.
    @inlinable
    init?(_length8 p: UnsafePointer<UInt8>) {
        switch unsafe p[0] {
        case 0x63:  // 'c'
            if unsafe _matchesSuffix(p, count: 8, 0x63, 0x6F, 0x6E, 0x74, 0x69, 0x6E, 0x75, 0x65) {
                self = .continue
                return
            }  // "continue"
            return nil

        case 0x69:  // 'i'
            if unsafe _matchesSuffix(p, count: 8, 0x69, 0x6E, 0x64, 0x69, 0x72, 0x65, 0x63, 0x74) {
                self = .indirect
                return
            }  // "indirect"
            if unsafe _matchesSuffix(p, count: 8, 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E, 0x61, 0x6C) {
                self = .internal
                return
            }  // "internal"
            return nil

        case 0x6D:  // 'm'
            if unsafe _matchesSuffix(p, count: 8, 0x6D, 0x75, 0x74, 0x61, 0x74, 0x69, 0x6E, 0x67) {
                self = .mutating
                return
            }  // "mutating"
            return nil

        case 0x6F:  // 'o'
            if unsafe _matchesSuffix(p, count: 8, 0x6F, 0x70, 0x65, 0x72, 0x61, 0x74, 0x6F, 0x72) {
                self = .operator
                return
            }  // "operator"
            return nil

        case 0x70:  // 'p'
            if unsafe _matchesSuffix(p, count: 8, 0x70, 0x72, 0x6F, 0x74, 0x6F, 0x63, 0x6F, 0x6C) {
                self = .protocol
                return
            }  // "protocol"
            return nil

        default:
            return nil
        }
    }

    /// Matches keywords of length 9: borrowing, consuming, extension,
    /// subscript, typealias.
    @inlinable
    init?(_length9 p: UnsafePointer<UInt8>) {
        switch unsafe p[0] {
        case 0x62:  // 'b'
            if unsafe _matchesSuffix(p, count: 9, 0x62, 0x6F, 0x72, 0x72, 0x6F, 0x77, 0x69, 0x6E, 0x67) {
                self = .borrowing
                return
            }  // "borrowing"
            return nil

        case 0x63:  // 'c'
            if unsafe _matchesSuffix(p, count: 9, 0x63, 0x6F, 0x6E, 0x73, 0x75, 0x6D, 0x69, 0x6E, 0x67) {
                self = .consuming
                return
            }  // "consuming"
            return nil

        case 0x65:  // 'e'
            if unsafe _matchesSuffix(p, count: 9, 0x65, 0x78, 0x74, 0x65, 0x6E, 0x73, 0x69, 0x6F, 0x6E) {
                self = .extension
                return
            }  // "extension"
            return nil

        case 0x73:  // 's'
            if unsafe _matchesSuffix(p, count: 9, 0x73, 0x75, 0x62, 0x73, 0x63, 0x72, 0x69, 0x70, 0x74) {
                self = .subscript
                return
            }  // "subscript"
            return nil

        case 0x74:  // 't'
            if unsafe _matchesSuffix(p, count: 9, 0x74, 0x79, 0x70, 0x65, 0x61, 0x6C, 0x69, 0x61, 0x73) {
                self = .typealias
                return
            }  // "typealias"
            return nil

        default:
            return nil
        }
    }

    /// Matches keywords of length 11: fallthrough, fileprivate, nonmutating.
    @inlinable
    init?(_length11 p: UnsafePointer<UInt8>) {
        switch unsafe p[0] {
        case 0x66:  // 'f'
            if unsafe _matchesLong(p, "fallthrough") {
                self = .fallthrough
                return
            }
            if unsafe _matchesLong(p, "fileprivate") {
                self = .fileprivate
                return
            }
            return nil

        case 0x6E:  // 'n'
            if unsafe _matchesLong(p, "nonmutating") {
                self = .nonmutating
                return
            }
            return nil

        default:
            return nil
        }
    }

    /// Matches keywords of length 14: associatedtype.
    @inlinable
    init?(_length14 p: UnsafePointer<UInt8>) {
        if unsafe _matchesLong(p, "associatedtype") {
            self = .associatedtype
            return
        }
        return nil
    }

    /// Matches keywords of length 15: precedencegroup.
    @inlinable
    init?(_length15 p: UnsafePointer<UInt8>) {
        if unsafe _matchesLong(p, "precedencegroup") {
            self = .precedencegroup
            return
        }
        return nil
    }
}

// MARK: - Byte Comparison Helpers

/// Matches 4 bytes at the given pointer.
@inlinable
@inline(always)
func _matches(
    _ p: UnsafePointer<UInt8>,
    _ b0: UInt8,
    _ b1: UInt8,
    _ b2: UInt8,
    _ b3: UInt8
) -> Bool {
    unsafe (p[0] == b0 && p[1] == b1 && p[2] == b2 && p[3] == b3)
}

/// Matches 5 bytes at the given pointer.
@inlinable
@inline(always)
func _matches5(
    _ p: UnsafePointer<UInt8>,
    _ b0: UInt8,
    _ b1: UInt8,
    _ b2: UInt8,
    _ b3: UInt8,
    _ b4: UInt8
) -> Bool {
    unsafe (p[0] == b0 && p[1] == b1 && p[2] == b2
        && p[3] == b3 && p[4] == b4)
}

/// Matches bytes 1...5 at the given pointer (byte 0 already checked by caller).
@inlinable
@inline(always)
func _matchesTail5(
    _ p: UnsafePointer<UInt8>,
    _ b1: UInt8,
    _ b2: UInt8,
    _ b3: UInt8,
    _ b4: UInt8,
    _ b5: UInt8
) -> Bool {
    unsafe (p[1] == b1 && p[2] == b2 && p[3] == b3
        && p[4] == b4 && p[5] == b5)
}

/// Matches N bytes at the given pointer (variadic, for lengths 7-9).
@inlinable
@inline(always)
func _matchesSuffix(
    _ p: UnsafePointer<UInt8>,
    count: Int,
    _ b0: UInt8,
    _ b1: UInt8,
    _ b2: UInt8,
    _ b3: UInt8,
    _ b4: UInt8,
    _ b5: UInt8,
    _ b6: UInt8
) -> Bool {
    unsafe (p[0] == b0 && p[1] == b1 && p[2] == b2
        && p[3] == b3 && p[4] == b4 && p[5] == b5
        && p[6] == b6)
}

@inlinable
@inline(always)
func _matchesSuffix(
    _ p: UnsafePointer<UInt8>,
    count: Int,
    _ b0: UInt8,
    _ b1: UInt8,
    _ b2: UInt8,
    _ b3: UInt8,
    _ b4: UInt8,
    _ b5: UInt8,
    _ b6: UInt8,
    _ b7: UInt8
) -> Bool {
    unsafe (p[0] == b0 && p[1] == b1 && p[2] == b2
        && p[3] == b3 && p[4] == b4 && p[5] == b5
        && p[6] == b6 && p[7] == b7)
}

@inlinable
@inline(always)
func _matchesSuffix(
    _ p: UnsafePointer<UInt8>,
    count: Int,
    _ b0: UInt8,
    _ b1: UInt8,
    _ b2: UInt8,
    _ b3: UInt8,
    _ b4: UInt8,
    _ b5: UInt8,
    _ b6: UInt8,
    _ b7: UInt8,
    _ b8: UInt8
) -> Bool {
    unsafe (p[0] == b0 && p[1] == b1 && p[2] == b2
        && p[3] == b3 && p[4] == b4 && p[5] == b5
        && p[6] == b6 && p[7] == b7 && p[8] == b8)
}

/// Matches a long keyword using StaticString comparison.
@inlinable
@inline(always)
func _matchesLong(_ p: UnsafePointer<UInt8>, _ keyword: StaticString) -> Bool {
    let kp = unsafe keyword.utf8Start
    let count = keyword.utf8CodeUnitCount
    for i in 0..<count {
        if unsafe (p[i] != kp[i]) { return false }
    }
    return true
}
