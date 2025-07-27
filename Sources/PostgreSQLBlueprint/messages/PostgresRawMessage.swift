
import Logging
import SQLBlueprint
import SwiftDatabaseBlueprint

// https://www.postgresql.org/docs/current/protocol-message-formats.html
public struct PostgresRawMessage: PostgresRawMessageProtocol {
    public let type:UInt8
    public let bodyCount:Int32
    public let body:ByteBuffer

    @usableFromInline
    init(
        type: UInt8,
        bodyCount: Int32,
        body: ByteBuffer
    ) {
        self.type = type
        self.bodyCount = bodyCount
        self.body = body
    }
}

// MARK: Read
extension PostgresRawMessage {
    @inlinable
    public static func read(
        on connection: some PostgresConnectionProtocol
    ) async throws -> Self {
        let headerBuffer = try await connection.receive(length: 5)
        guard headerBuffer.count == 5 else {
            throw PostgresError.readMessage("headerBuffer.count (\(headerBuffer.count)) != 5")
        }
        let type = headerBuffer[0]
        let length:Int32 = headerBuffer.loadUnalignedIntBigEndian(offset: 1) - 4
        let body = try await connection.receive(length: Int(length))
        #if DEBUG
        connection.logger.info("Received message of type \(type) with body of length \(length)")
        #endif
        return Self(type: type, bodyCount: length, body: body)
    }
}