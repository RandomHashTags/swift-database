
import SQLBlueprint
import SwiftDatabaseBlueprint

// https://www.postgresql.org/docs/current/protocol-message-formats.html
public struct PostgresRawMessage: SQLRawMessageProtocol, @unchecked Sendable {
    public let type:UInt8
    public let body:UnsafeMutableBufferPointer<UInt8>

    public init(type: UInt8, body: UnsafeMutableBufferPointer<UInt8>) {
        self.type = type
        self.body = body
    }
}

// MARK: Parse
extension PostgresRawMessage {
    public static func parseFrontend(_ msg: PostgresRawMessage) -> Int? {
        switch msg.type {
        case .C: // command complete
            return nil
        default:
            return nil
        }
    }
}