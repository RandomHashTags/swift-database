
#if canImport(Android)
import Android
#elseif canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Windows)
import Windows
#elseif canImport(WinSDK)
import WinSDK
#endif

import Dispatch
import Logging
import SwiftDatabaseBlueprint

public protocol SQLConnectionProtocol: SQLQueryableProtocol, ~Copyable {
    associatedtype RawMessage: SQLRawMessageProtocol

    init()

    var fileDescriptor: Int32 { get }
    var logger: Logger { get }

    @inlinable
    mutating func establishConnection(storage: DatabaseStorageMethod) async throws

    @inlinable
    func shutdownConnection()

    @inlinable
    func closeFileDescriptor()

    /// Writes a buffer to the socket.
    @inlinable
    func writeBuffer(_ pointer: ByteBuffer) async throws
}

// MARK: Close file descriptor
extension SQLConnectionProtocol {
    @inlinable
    public func closeFileDescriptor() {
        shutdown(fileDescriptor, Int32(SHUT_RDWR))
        close(fileDescriptor)
    }
}

// MARK: Receive
extension SQLConnectionProtocol {
    @inlinable
    public func receive(length: Int, flags: Int32 = 0) async -> ByteBuffer {
        return await withCheckedContinuation { continutation in
            DispatchQueue.global().async {
                let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: length)
                let r = recv(fileDescriptor, buffer.baseAddress, length, flags)
                continutation.resume(returning: .init(buffer))
            }
        }
    }
}

// MARK: Write
extension SQLConnectionProtocol {
    @inlinable
    public func writeBuffer(_ buffer: ByteBuffer) async throws {
        let length = buffer.count
        var sent = 0
        while sent < length {
            if Task.isCancelled { return }
            let result = await sendMultiplatform(buffer, offset: sent, length: length - sent)
            if result <= 0 {
                throw SQLError.send(reason: "result (\(result)) <= 0")
            }
            sent += result
        }
    }

    @inlinable
    public func sendMultiplatform(_ pointer: ByteBuffer, offset: Int, length: Int) async -> Int {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: send(fileDescriptor, pointer.baseAddress! + offset, length, Int32(MSG_NOSIGNAL)))
            }
        }
    }
}