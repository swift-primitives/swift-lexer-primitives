extension Token.Keyword {

    @inlinable
    public init?(_ utf8: UnsafeBufferPointer<UInt8>) {
        guard let base = utf8.baseAddress else { return nil }
        switch utf8.count {
        case 2: unsafe self.init(_length2: base)
        case 3: unsafe self.init(_length3: base)
        case 4: unsafe self.init(_length4: base)
        case 5: unsafe self.init(_length5: base)
        case 6: unsafe self.init(_length6: base)
        case 7: unsafe self.init(_length7: base)
        case 8: unsafe self.init(_length8: base)
        case 9: unsafe self.init(_length9: base)
        case 11: unsafe self.init(_length11: base)
        case 14: unsafe self.init(_length14: base)
        case 15: unsafe self.init(_length15: base)
        default: return nil
        }
    }

    @inlinable
    public init?(_ utf8: UnsafeBufferPointer<Byte>) {
        guard let base = utf8.baseAddress else { return nil }
        let result: Token.Keyword? = unsafe base.withMemoryRebound(
            to: UInt8.self,
            capacity: utf8.count
        ) { ptr in
            unsafe Token.Keyword(unsafe UnsafeBufferPointer<UInt8>(start: ptr, count: utf8.count))
        }
        guard let result else { return nil }
        self = result
    }
}

extension Token.Keyword {

    @inlinable
    package init?(_length2 p: UnsafePointer<UInt8>) {
        switch (unsafe p[0], unsafe p[1]) {
        case (0x61, 0x73): self = .as
        case (0x64, 0x6F): self = .do
        case (0x69, 0x66): self = .if
        case (0x69, 0x6E): self = .in
        case (0x69, 0x73): self = .is
        default: return nil
        }
    }

    @inlinable
    package init?(_length3 p: UnsafePointer<UInt8>) {
        switch (unsafe p[0], unsafe p[1], unsafe p[2]) {
        case (0x61, 0x6E, 0x79): self = .any
        case (0x66, 0x6F, 0x72): self = .for
        case (0x67, 0x65, 0x74): self = .get
        case (0x6C, 0x65, 0x74): self = .let
        case (0x6E, 0x69, 0x6C): self = .nil
        case (0x73, 0x65, 0x74): self = .set
        case (0x74, 0x72, 0x79): self = .try
        case (0x76, 0x61, 0x72): self = .var
        default: return nil
        }
    }

    @inlinable
    package init?(_length4 p: UnsafePointer<UInt8>) {
        switch unsafe p[0] {
        case 0x63:
            if unsafe _matches(p, 0x63, 0x61, 0x73, 0x65) {
                self = .case
                return
            }
            return nil

        case 0x65:
            if unsafe _matches(p, 0x65, 0x61, 0x63, 0x68) {
                self = .each
                return
            }
            if unsafe _matches(p, 0x65, 0x6C, 0x73, 0x65) {
                self = .else
                return
            }
            if unsafe _matches(p, 0x65, 0x6E, 0x75, 0x6D) {
                self = .enum
                return
            }
            return nil

        case 0x66:
            if unsafe _matches(p, 0x66, 0x75, 0x6E, 0x63) {
                self = .func
                return
            }
            return nil

        case 0x69:
            if unsafe _matches(p, 0x69, 0x6E, 0x69, 0x74) {
                self = .`init`
                return
            }
            return nil

        case 0x73:
            if unsafe _matches(p, 0x73, 0x65, 0x6C, 0x66) {
                self = .`self`
                return
            }
            if unsafe _matches(p, 0x73, 0x6F, 0x6D, 0x65) {
                self = .some
                return
            }
            return nil

        case 0x53:
            if unsafe _matches(p, 0x53, 0x65, 0x6C, 0x66) {
                self = .`Self`
                return
            }
            return nil

        case 0x74:
            if unsafe _matches(p, 0x74, 0x72, 0x75, 0x65) {
                self = .`true`
                return
            }
            return nil

        default:
            return nil
        }
    }

    @inlinable
    package init?(_length5 p: UnsafePointer<UInt8>) {
        switch unsafe p[0] {
        case 0x5F:
            if unsafe _matches5(p, 0x5F, 0x72, 0x65, 0x61, 0x64) {
                self = ._read
                return
            }
            return nil

        case 0x62:
            if unsafe _matches5(p, 0x62, 0x72, 0x65, 0x61, 0x6B) {
                self = .break
                return
            }
            return nil

        case 0x63:
            if unsafe _matches5(p, 0x63, 0x61, 0x74, 0x63, 0x68) {
                self = .catch
                return
            }
            return nil

        case 0x64:
            if unsafe _matches5(p, 0x64, 0x65, 0x66, 0x65, 0x72) {
                self = .defer
                return
            }
            return nil

        case 0x66:
            if unsafe _matches5(p, 0x66, 0x61, 0x6C, 0x73, 0x65) {
                self = .`false`
                return
            }
            return nil

        case 0x67:
            if unsafe _matches5(p, 0x67, 0x75, 0x61, 0x72, 0x64) {
                self = .guard
                return
            }
            return nil

        case 0x69:
            if unsafe _matches5(p, 0x69, 0x6E, 0x6F, 0x75, 0x74) {
                self = .inout
                return
            }
            return nil

        case 0x74:
            if unsafe _matches5(p, 0x74, 0x68, 0x72, 0x6F, 0x77) {
                self = .throw
                return
            }
            return nil

        case 0x77:
            if unsafe _matches5(p, 0x77, 0x68, 0x65, 0x72, 0x65) {
                self = .where
                return
            }
            if unsafe _matches5(p, 0x77, 0x68, 0x69, 0x6C, 0x65) {
                self = .while
                return
            }
            return nil

        case 0x79:
            if unsafe _matches5(p, 0x79, 0x69, 0x65, 0x6C, 0x64) {
                self = .yield
                return
            }
            return nil

        default:
            return nil
        }
    }

    @inlinable
    package init?(_length6 p: UnsafePointer<UInt8>) {
        switch unsafe p[0] {
        case 0x64:
            if unsafe _matchesTail5(p, 0x65, 0x69, 0x6E, 0x69, 0x74) {
                self = .deinit
                return
            }
            return nil

        case 0x69:
            if unsafe _matchesTail5(p, 0x6D, 0x70, 0x6F, 0x72, 0x74) {
                self = .import
                return
            }
            return nil

        case 0x70:
            if unsafe _matchesTail5(p, 0x75, 0x62, 0x6C, 0x69, 0x63) {
                self = .public
                return
            }
            return nil

        case 0x72:
            if unsafe _matchesTail5(p, 0x65, 0x70, 0x65, 0x61, 0x74) {
                self = .repeat
                return
            }
            if unsafe _matchesTail5(p, 0x65, 0x74, 0x75, 0x72, 0x6E) {
                self = .return
                return
            }
            return nil

        case 0x73:
            if unsafe _matchesTail5(p, 0x74, 0x61, 0x74, 0x69, 0x63) {
                self = .static
                return
            }
            if unsafe _matchesTail5(p, 0x74, 0x72, 0x75, 0x63, 0x74) {
                self = .struct
                return
            }
            if unsafe _matchesTail5(p, 0x77, 0x69, 0x74, 0x63, 0x68) {
                self = .switch
                return
            }
            return nil

        case 0x74:
            if unsafe _matchesTail5(p, 0x68, 0x72, 0x6F, 0x77, 0x73) {
                self = .throws
                return
            }
            return nil

        default:
            return nil
        }
    }

    @inlinable
    package init?(_length7 p: UnsafePointer<UInt8>) {
        switch unsafe p[0] {
        case 0x5F:
            if unsafe _matchesSuffix(p, count: 7, (0x5F, 0x6D, 0x6F, 0x64, 0x69, 0x66, 0x79)) {
                self = ._modify
                return
            }
            return nil

        case 0x64:
            if unsafe _matchesSuffix(p, count: 7, (0x64, 0x65, 0x66, 0x61, 0x75, 0x6C, 0x74)) {
                self = .default
                return
            }
            if unsafe _matchesSuffix(p, count: 7, (0x64, 0x69, 0x73, 0x63, 0x61, 0x72, 0x64)) {
                self = .discard
                return
            }
            return nil

        case 0x70:
            if unsafe _matchesSuffix(p, count: 7, (0x70, 0x61, 0x63, 0x6B, 0x61, 0x67, 0x65)) {
                self = .package
                return
            }
            if unsafe _matchesSuffix(p, count: 7, (0x70, 0x72, 0x69, 0x76, 0x61, 0x74, 0x65)) {
                self = .private
                return
            }
            return nil

        default:
            return nil
        }
    }

    @inlinable
    package init?(_length8 p: UnsafePointer<UInt8>) {
        switch unsafe p[0] {
        case 0x63:
            if unsafe _matchesSuffix(p, count: 8, (0x63, 0x6F, 0x6E, 0x74, 0x69, 0x6E, 0x75, 0x65))
            {
                self = .continue
                return
            }
            return nil

        case 0x69:
            if unsafe _matchesSuffix(p, count: 8, (0x69, 0x6E, 0x64, 0x69, 0x72, 0x65, 0x63, 0x74))
            {
                self = .indirect
                return
            }
            if unsafe _matchesSuffix(p, count: 8, (0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E, 0x61, 0x6C))
            {
                self = .internal
                return
            }
            return nil

        case 0x6D:
            if unsafe _matchesSuffix(p, count: 8, (0x6D, 0x75, 0x74, 0x61, 0x74, 0x69, 0x6E, 0x67))
            {
                self = .mutating
                return
            }
            return nil

        case 0x6F:
            if unsafe _matchesSuffix(p, count: 8, (0x6F, 0x70, 0x65, 0x72, 0x61, 0x74, 0x6F, 0x72))
            {
                self = .operator
                return
            }
            return nil

        case 0x70:
            if unsafe _matchesSuffix(p, count: 8, (0x70, 0x72, 0x6F, 0x74, 0x6F, 0x63, 0x6F, 0x6C))
            {
                self = .protocol
                return
            }
            return nil

        default:
            return nil
        }
    }

    @inlinable
    package init?(_length9 p: UnsafePointer<UInt8>) {
        switch unsafe p[0] {
        case 0x62:
            if unsafe _matchesSuffix(
                p,
                count: 9,
                (0x62, 0x6F, 0x72, 0x72, 0x6F, 0x77, 0x69, 0x6E, 0x67)
            ) {
                self = .borrowing
                return
            }
            return nil

        case 0x63:
            if unsafe _matchesSuffix(
                p,
                count: 9,
                (0x63, 0x6F, 0x6E, 0x73, 0x75, 0x6D, 0x69, 0x6E, 0x67)
            ) {
                self = .consuming
                return
            }
            return nil

        case 0x65:
            if unsafe _matchesSuffix(
                p,
                count: 9,
                (0x65, 0x78, 0x74, 0x65, 0x6E, 0x73, 0x69, 0x6F, 0x6E)
            ) {
                self = .extension
                return
            }
            return nil

        case 0x73:
            if unsafe _matchesSuffix(
                p,
                count: 9,
                (0x73, 0x75, 0x62, 0x73, 0x63, 0x72, 0x69, 0x70, 0x74)
            ) {
                self = .subscript
                return
            }
            return nil

        case 0x74:
            if unsafe _matchesSuffix(
                p,
                count: 9,
                (0x74, 0x79, 0x70, 0x65, 0x61, 0x6C, 0x69, 0x61, 0x73)
            ) {
                self = .typealias
                return
            }
            return nil

        default:
            return nil
        }
    }

    @inlinable
    package init?(_length11 p: UnsafePointer<UInt8>) {
        switch unsafe p[0] {
        case 0x66:
            if unsafe _matchesLong(p, "fallthrough") {
                self = .fallthrough
                return
            }
            if unsafe _matchesLong(p, "fileprivate") {
                self = .fileprivate
                return
            }
            return nil

        case 0x6E:
            if unsafe _matchesLong(p, "nonmutating") {
                self = .nonmutating
                return
            }
            return nil

        default:
            return nil
        }
    }

    @inlinable
    package init?(_length14 p: UnsafePointer<UInt8>) {
        if unsafe _matchesLong(p, "associatedtype") {
            self = .associatedtype
            return
        }
        return nil
    }

    @inlinable
    package init?(_length15 p: UnsafePointer<UInt8>) {
        if unsafe _matchesLong(p, "precedencegroup") {
            self = .precedencegroup
            return
        }
        return nil
    }
}

@inlinable
@inline(always)
package func _matches(
    _ p: UnsafePointer<UInt8>,
    _ b0: UInt8,
    _ b1: UInt8,
    _ b2: UInt8,
    _ b3: UInt8
) -> Bool {
    unsafe (p[0] == b0 && p[1] == b1 && p[2] == b2 && p[3] == b3)
}

@inlinable
@inline(always)
package func _matches5(
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

@inlinable
@inline(always)
package func _matchesTail5(
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

@inlinable
@inline(always)
package func _matchesSuffix(
    _ p: UnsafePointer<UInt8>,
    count: Int,
    _ bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
) -> Bool {
    unsafe (p[0] == bytes.0 && p[1] == bytes.1 && p[2] == bytes.2
        && p[3] == bytes.3 && p[4] == bytes.4 && p[5] == bytes.5
        && p[6] == bytes.6)
}

@inlinable
@inline(always)
package func _matchesSuffix(
    _ p: UnsafePointer<UInt8>,
    count: Int,
    _ bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
) -> Bool {
    unsafe (p[0] == bytes.0 && p[1] == bytes.1 && p[2] == bytes.2
        && p[3] == bytes.3 && p[4] == bytes.4 && p[5] == bytes.5
        && p[6] == bytes.6 && p[7] == bytes.7)
}

@inlinable
@inline(always)
package func _matchesSuffix(
    _ p: UnsafePointer<UInt8>,
    count: Int,
    _ bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
) -> Bool {
    unsafe (p[0] == bytes.0 && p[1] == bytes.1 && p[2] == bytes.2
        && p[3] == bytes.3 && p[4] == bytes.4 && p[5] == bytes.5
        && p[6] == bytes.6 && p[7] == bytes.7 && p[8] == bytes.8)
}

@inlinable
@inline(always)
package func _matchesLong(_ p: UnsafePointer<UInt8>, _ keyword: StaticString) -> Bool {
    let kp = unsafe keyword.utf8Start
    let count = keyword.utf8CodeUnitCount
    return (0..<count).allSatisfy { unsafe p[$0] == kp[$0] }
}
