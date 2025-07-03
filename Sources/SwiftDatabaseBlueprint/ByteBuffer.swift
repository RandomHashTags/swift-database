
public final class ByteBuffer: @unchecked Sendable {
    @usableFromInline
    let buffer:UnsafeMutableBufferPointer<UInt8>

    @inlinable
    package init(_ buffer: UnsafeMutableBufferPointer<UInt8>) {
        self.buffer = buffer
    }

    @inlinable
    package init(capacity: Int) {
        buffer = .allocate(capacity: capacity)
    }

    @inlinable
    public subscript(_ index: Int) -> UInt8 {
        get {
            buffer[index]
        }
        set {
            buffer[index] = newValue
        }
    }

    @inlinable
    public var baseAddress: UnsafeMutablePointer<UInt8>? {
        buffer.baseAddress
    }

    @inlinable
    public var count: Int {
        buffer.count
    }

    @inlinable
    public var indices: Range<Int> {
        buffer.indices
    }

    deinit {
        buffer.deallocate()
    }
}

extension ByteBuffer {
    @inlinable
    public func bytes() -> [UInt8] {
        [UInt8](buffer)
    }

    @inlinable
    public subscript(_ range: Range<Int>) -> Slice<UnsafeMutableBufferPointer<UInt8>> {
        buffer[range]
    }

    @inlinable
    public func utf8String() -> String {
        return String.init(decoding: bytes(), as: UTF8.self)
    }
}

extension ByteBuffer {
    @inlinable
    public func postgresBYTEAHexadecimal() -> String {
        var fullValue = ""
        let cap = (buffer.count-2) / 2
        if cap > 0 {
            fullValue.reserveCapacity(cap)
        }
        var i = 2
        while i < count {
            let bytes = buffer[i..<i+2]
            if let s = String.decodeCString(bytes + [0], as: UTF8.self), let uint8 = UInt8(s.result, radix: 16) {
                fullValue.append(Character(Unicode.Scalar(uint8)))
            }
            i += 2
        }
        return fullValue
    }
}