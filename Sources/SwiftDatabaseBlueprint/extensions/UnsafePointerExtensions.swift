

#if canImport(Android)
import Android
#elseif canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(WinSDK)
import WinSDK
#endif

// MARK: Copy buffer
extension UnsafeMutableBufferPointer where Element == UInt8 {
    @inlinable
    public func copyBuffer(_ buffer: UnsafeBufferPointer<Element>, to index: Int) {
        var index = index
        copyBuffer(buffer, to: &index)
    }

    @inlinable
    public func copyBuffer(_ buffer: UnsafeMutableBufferPointer<Element>, to index: Int) {
        var index = index
        copyBuffer(buffer, to: &index)
    }

    @inlinable
    public func copyBuffer(_ buffer: UnsafePointer<Element>, count: Int, to index: Int) {
        var index = index
        copyBuffer(buffer, count: count, to: &index)
    }

    @inlinable
    public func copyBuffer(_ buffer: UnsafeMutableBufferPointer<Element>, offset: Int = 0, count: Int, to index: Int) {
        var index = index
        copyBuffer(buffer.baseAddress!, offset: offset, count: count, to: &index)
    }

    @inlinable
    public func copyBuffer(_ buffer: UnsafeBufferPointer<Element>, to index: inout Int) {
        copyBuffer(buffer.baseAddress!, count: buffer.count, to: &index)
    }

    @inlinable
    public func copyBuffer(_ buffer: UnsafeMutableBufferPointer<Element>, to index: inout Int) {
        copyBuffer(buffer.baseAddress!, count: buffer.count, to: &index)
    }

    @inlinable
    public func copyBuffer(_ buffer: UnsafeMutableBufferPointer<Element>, offset: Int = 0, count: Int, to index: inout Int) {
        copyBuffer(buffer.baseAddress!, offset: offset, count: count, to: &index)
    }
    
    @inlinable
    public func copyBuffer(_ buffer: UnsafeMutablePointer<Element>, offset: Int = 0, count: Int, to index: inout Int) {
        #if canImport(Android) || canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(WinSDK)
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
    public func copyBuffer(_ buffer: UnsafePointer<Element>, offset: Int = 0, count: Int, to index: inout Int) {
        #if canImport(Android) || canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(WinSDK)
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
extension UnsafeMutableBufferPointer where Element == UInt8 {
    @inlinable
    public func loadInt<T: BinaryInteger>() -> T {
        return UnsafeRawPointer(baseAddress!).load(as: T.self)
    }

    @inlinable
    public func loadInt<T: BinaryInteger>(offset: Int) -> T {
        return UnsafeRawPointer(baseAddress! + offset).load(as: T.self)
    }
}