

#if canImport(Android)
import Android
#elseif canImport(Bionic)
import Bionic
#elseif canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(WASILibc)
import WASILibc
#elseif canImport(Windows)
import Windows
#elseif canImport(WinSDK)
import WinSDK
#endif

// MARK: Copy buffer
extension ByteBuffer {
    @inlinable
    public func copyBuffer(_ buffer: UnsafeBufferPointer<UInt8>, to index: Int) {
        var index = index
        copyBuffer(buffer, to: &index)
    }

    @inlinable
    public func copyBuffer(_ buffer: UnsafeMutableBufferPointer<UInt8>, to index: Int) {
        var index = index
        copyBuffer(buffer, to: &index)
    }

    @inlinable
    public func copyBuffer(_ buffer: UnsafePointer<UInt8>, count: Int, to index: Int) {
        var index = index
        copyBuffer(buffer, count: count, to: &index)
    }

    @inlinable
    public func copyBuffer(_ buffer: UnsafeMutableBufferPointer<UInt8>, offset: Int = 0, count: Int, to index: Int) {
        var index = index
        copyBuffer(buffer.baseAddress!, offset: offset, count: count, to: &index)
    }

    @inlinable
    public func copyBuffer(_ buffer: UnsafeBufferPointer<UInt8>, to index: inout Int) {
        copyBuffer(buffer.baseAddress!, count: buffer.count, to: &index)
    }

    @inlinable
    public func copyBuffer(_ buffer: UnsafeMutableBufferPointer<UInt8>, to index: inout Int) {
        copyBuffer(buffer.baseAddress!, count: buffer.count, to: &index)
    }

    @inlinable
    public func copyBuffer(_ buffer: UnsafeMutableBufferPointer<UInt8>, offset: Int = 0, count: Int, to index: inout Int) {
        copyBuffer(buffer.baseAddress!, offset: offset, count: count, to: &index)
    }
    
    @inlinable
    public func copyBuffer(_ buffer: UnsafeMutablePointer<UInt8>, offset: Int = 0, count: Int, to index: inout Int) {
        #if canImport(Android) || canImport(Bionic) || canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(WASILibc) || canImport(Windows) || canImport(WinSDK)
        memcpy(baseAddress! + index, buffer + offset, count)
        index += count
        #else
        for i in 0..<count {
            self[index] = buffer[offset + i]
            index += 1
        }
        #endif
    }

    @inlinable
    public func copyBuffer(_ buffer: UnsafePointer<UInt8>, offset: Int = 0, count: Int, to index: inout Int) {
        #if canImport(Android) || canImport(Bionic) || canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(WASILibc) || canImport(Windows) || canImport(WinSDK)
        memcpy(baseAddress! + index, buffer + offset, count)
        index += count
        #else
        for i in 0..<count {
            self[index] = buffer[offset + i]
            index += 1
        }
        #endif
    }
}

// MARK: Load Int
extension ByteBuffer {
    @inlinable
    public func loadUnalignedInt<T: BinaryInteger>() -> T {
        return UnsafeRawPointer(baseAddress!).load(as: T.self)
    }

    @inlinable
    public func loadUnalignedInt<T: BinaryInteger>(offset: Int) -> T {
        return UnsafeRawPointer(baseAddress! + offset).loadUnaligned(as: T.self)
    }

    @inlinable
    public func loadUnalignedIntBigEndian<T: FixedWidthInteger>() -> T {
        return UnsafeRawPointer(baseAddress!).loadUnaligned(as: T.self).bigEndian
    }
    
    @inlinable
    public func loadUnalignedIntBigEndian<T: FixedWidthInteger>(offset: Int) -> T {
        return UnsafeRawPointer(baseAddress! + offset).loadUnaligned(as: T.self).bigEndian
    }
}

// MARK: Load string
extension ByteBuffer {
    @inlinable
    public func loadNullTerminatedString() -> String {
        return String(cString: baseAddress!)
    }

    @inlinable
    public func loadNullTerminatedString(offset: Int) -> String {
        return String(cString: baseAddress! + offset)
    }

    @discardableResult
    @inlinable
    public func loadNullTerminatedStringBigEndian(offset: Int) -> (string: String, length: Int)? {
        var i = offset
        while i < count {
            if self[i] == 0 {
                let length = i - offset + 1
                return (withUnsafeTemporaryAllocation(of: UInt8.self, capacity: length, { buffer in
                    memcpy(buffer.baseAddress!, self.baseAddress! + offset, i - offset + 1) // TODO: fix?
                    return String.init(cString: buffer.baseAddress!)
                }), length)
            }
            i += 1
        }
        return nil
    }

    @inlinable
    public func loadStringBigEndian(offset: Int, count: Int) -> String {
        let other = baseAddress! + offset
        return withUnsafeTemporaryAllocation(of: UInt8.self, capacity: count + 1, { buffer in
            buffer.initialize(repeating: 0)
            var i = 0
            while i < count {
                buffer[i] = other[i].bigEndian
                i += 1
            }
            return String.init(cString: buffer.baseAddress!)
        })
    }
}

// MARK: Load ByteBuffer
extension ByteBuffer {
    @inlinable
    public func loadByteBufferBigEndian(offset: Int, count: Int) -> ByteBuffer {
        let other = baseAddress! + offset
        let buffer = ByteBuffer(capacity: count)
        var i = 0
        while i < count {
            buffer[i] = other[i].bigEndian
            i += 1
        }
        return buffer
    }
}

// MARK: Write int
extension ByteBuffer {
    @inlinable
    public func writeIntBigEndian<T: FixedWidthInteger>(_ value: T, to index: inout Int) {
        withUnsafeBytes(of: value.bigEndian, {
            $0.forEach {
                self[index] = $0
                index += 1
            }
        })
    }
}