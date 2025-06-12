
import SwiftDatabaseBlueprint

public struct PostgresMessage: @unchecked Sendable {
    public let type:UInt8
    public let body:UnsafeMutableBufferPointer<UInt8>

    public init(type: UInt8, body: UnsafeMutableBufferPointer<UInt8>) {
        self.type = type
        self.body = body
    }
}

// MARK: Parse
extension PostgresMessage {
    // https://www.postgresql.org/docs/current/protocol-message-formats.html
    public static func parseBackend(_ buffer: UnsafeMutableBufferPointer<UInt8>) -> (any PostgresMessageProtocol)? {
        switch buffer[0] {
        case .R: // authentication
            return nil
        case .K: // backend key data
            return nil
        case .B: // bind
            return nil
        case .`2`: // bind complete
            return nil
        case .C: // close
            return nil
        case .`3`: // close complete
            return nil
        case .C: // command complete
            return nil
        case .d: // copy data
            return nil
        case .c: // copy done
            return nil
        case .f: // copy fail
            return nil
        case .G: // copy in response
            return nil
        case .H: // copy out response
            return nil
        case .W: // copy both response
            return nil
        case .D: // data row
            return nil
        case .I: // empty query response
            return nil
        case .E: // error response
            return nil
        case .V: // function call response
            return nil
        case .v: // negotiate protocol version
            return nil
        case .n: // no data
            return nil
        case .N: // notice response
            return nil
        case .A: // notification response
            return nil
        case .t: // parameter description
            return nil
        case .S: // parameter status
            return nil
        case .`1`: // parse complete
            return nil
        case .s: // portal suspended
            return nil
        case .Z: // ready for query
            return nil
        case .T: // row description
            return nil
        default:
            return nil
        }
    }
}