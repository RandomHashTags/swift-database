
import Logging
import SQLBlueprint
import SwiftDatabaseBlueprint

public protocol PostgresConnectionProtocol: SQLConnectionProtocol, ~Copyable where RawMessage == PostgresRawMessage {
    @inlinable
    func readMessage(_ closure: (RawMessage) throws -> Void) throws

    @inlinable
    func sendMessage<T: PostgresFrontendMessageProtocol>(_ message: inout T) throws
}

// MARK: Read message
extension PostgresConnectionProtocol {
    @inlinable
    public func readMessage(_ closure: (RawMessage) throws -> Void) throws {
        try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 5, { headerBuffer in
            let received = receive(baseAddress: headerBuffer.baseAddress!, length: 5)
            guard received == 5 else {
                throw PostgresError.readMessage("received (\(received)) != 5")
            }
            let type = headerBuffer[0]
            let length:Int32 = headerBuffer.loadUnalignedIntBigEndian(offset: 1)
            try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: Int(length), { buffer in
                var i = 0
                withUnsafeBytes(of: length, {
                    $0.forEach {
                        buffer[i] = $0
                        i += 1
                    }
                })
                _ = receive(baseAddress: buffer.baseAddress! + i, length: Int(length) - i)
                #if DEBUG
                logger.info("Received message of type \(type) with body of length \(length)")
                #endif
                try closure(RawMessage(type: type, body: buffer))
            })
        })
    }
}

// MARK: Send message
extension PostgresConnectionProtocol {
    @inlinable
    public func sendMessage<T: PostgresFrontendMessageProtocol>(_ message: inout T) throws {
        #if DEBUG
        logger.info("Sending message: \(message)")
        #endif
        try message.write(to: self)
    }
}