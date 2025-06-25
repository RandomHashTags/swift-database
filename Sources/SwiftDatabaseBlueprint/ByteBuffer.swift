
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