
#if canImport(Android)
import Android
#elseif canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WinSDK)
import WinSDK
#endif

public protocol SQLConnectionProtocol: Sendable, ~Copyable {
    associatedtype RawMessage: SQLRawMessageProtocol

    init()

    var fileDescriptor: Int32 { get }

    @inlinable
    mutating func establishConnection(
        address: String,
        port: UInt16
    ) async throws

    func query(_ query: String) async throws -> RawMessage

    @inlinable
    func shutdownConnection()

    @inlinable
    func closeFileDescriptor()

    /// Writes a buffer to the socket.
    @inlinable
    func writeBuffer(_ pointer: UnsafeRawPointer, length: Int) throws
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
    public func receive(baseAddress: UnsafeMutablePointer<UInt8>, length: Int, flags: Int32 = 0) -> Int {
        return recv(fileDescriptor, baseAddress, length, flags)
    }

    @inlinable
    public func receive(baseAddress: UnsafeMutableRawPointer, length: Int, flags: Int32 = 0) -> Int {
        return recv(fileDescriptor, baseAddress, length, flags)
    }
}

// MARK: Write
extension SQLConnectionProtocol {
    @inlinable
    public func writeBuffer(_ buffer: UnsafeRawPointer, length: Int) throws {
        var sent = 0
        while sent < length {
            if Task.isCancelled { return }
            let result = sendMultiplatform(buffer + sent, length - sent)
            if result <= 0 {
                fatalError("socket send error")
            }
            sent += result
        }
    }

    @inlinable
    public func sendMultiplatform(_ pointer: UnsafeRawPointer, _ length: Int) -> Int {
        return send(fileDescriptor, pointer, length, Int32(MSG_NOSIGNAL))
    }
}
