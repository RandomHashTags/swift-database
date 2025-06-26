
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
    public func receive(length: Int, flags: Int32 = 0) async throws -> ByteBuffer {
        let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: length)
        while true {
            let r = recv(fileDescriptor, buffer.baseAddress, length, flags)
            if r > 0 {
                return .init(buffer)
            } else if r == 0 {
                buffer.deallocate()
                throw SQLError.receive(reason: "r == 0; end of file")
            } else if errno == EAGAIN || errno == EWOULDBLOCK {
                try await waitUntilReadable()
                let _ = recv(fileDescriptor, buffer.baseAddress, length, flags)
                return .init(buffer)
            } else {
                let err = errno
                buffer.deallocate()
                throw SQLError.receive(reason: "err=\(err)")
            }
        }
    }
    @inlinable
    func waitUntilReadable() async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                var pfd = pollfd(fd: fileDescriptor, events: Int16(POLLIN), revents: 0)
                let r = poll(&pfd, 1, -1)
                if r > 0 {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: SQLError.receive(reason: "waitUntilReadable;r=\(r);errno=\(errno)"))
                }
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
            let result = try await sendMultiplatform(buffer, offset: sent, length: length - sent)
            if result <= 0 {
                throw SQLError.send(reason: "result (\(result)) <= 0")
            }
            sent += result
        }
    }

    @inlinable
    public func sendMultiplatform(_ pointer: ByteBuffer, offset: Int, length: Int) async throws -> Int {
        let ptr = pointer.baseAddress! + offset
        while true {
            let sent = send(fileDescriptor, ptr, length, Int32(MSG_NOSIGNAL))
            if sent >= 0 {
                return sent
            } else if errno == EAGAIN || errno == EWOULDBLOCK {
                try await waitUntilWriteable()
                return send(fileDescriptor, ptr, length, Int32(MSG_NOSIGNAL))
            } else {
                throw SQLError.send(reason: "sentMultiplatform;sent=\(sent);errno=\(errno)")
            }
        }
    }

    @inlinable
    func waitUntilWriteable() async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                var pfd = pollfd(fd: fileDescriptor, events: Int16(POLLOUT), revents: 0)
                let r = poll(&pfd, 1, -1)
                if r > 0 {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: SQLError.send(reason: "waitUntilWriteable;r=\(r);errno=\(errno)"))
                }
            }
        }
    }
}