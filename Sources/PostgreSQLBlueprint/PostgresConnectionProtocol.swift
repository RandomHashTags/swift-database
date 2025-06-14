
import Logging
import SQLBlueprint
import SwiftDatabaseBlueprint

public protocol PostgresConnectionProtocol: SQLConnectionProtocol, ~Copyable where RawMessage == PostgresRawMessage {
    @inlinable
    func readMessage(_ closure: (PostgresRawMessage) throws -> Void) throws

    @inlinable
    func sendMessage<T: PostgresFrontendMessageProtocol>(_ message: inout T) throws
}

// MARK: Read message
extension PostgresConnectionProtocol {
    @inlinable
    public func readMessage(_ closure: (PostgresRawMessage) throws -> Void) throws {
        try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 5, { headerBuffer in
            let received = receive(baseAddress: headerBuffer.baseAddress!, length: 5)
            guard received == 5 else {
                throw PostgresError.readMessage("received (\(received)) != 5")
            }
            let type = headerBuffer[0]
            let length:UInt32 = headerBuffer.loadUnalignedIntBigEndian(offset: 1) - 4
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: Int(length), { buffer in
                _ = receive(baseAddress: buffer.baseAddress!, length: Int(length))
                logger.debug("Received message of type \(type) and length \(length)")
                try closure(PostgresRawMessage(type: type, body: buffer))
            })
        })
    }
}

// MARK: Send message
extension PostgresConnectionProtocol {
    @inlinable
    public func sendMessage<T: PostgresFrontendMessageProtocol>(_ message: inout T) throws {
        logger.debug("Sending message: \(T.self)")
        try message.write(to: self)
    }
}