
import PostgreSQLBlueprint
import SQLBlueprint
import SwiftDatabaseBlueprint

/// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-BIND
public struct PostgresBindMessage<
        let trailingParameterFormatCodesCount: Int,
        let parameterValuesCount: Int
    >: PostgresBindMessageProtocol { // TODO: finish
    public var destinationPortal:String
    public var sourcePreparedStatement:String
    public var trailingParameterFormatCodes:InlineArray<trailingParameterFormatCodesCount, Int16>
    public var parameters:InlineArray<parameterValuesCount, Parameters<Parameter>>

    @inlinable
    public init(
        destinationPortal: String,
        sourcePreparedStatement: String,
        trailingParameterFormatCodes: InlineArray<trailingParameterFormatCodesCount, Int16>,
        parameters: InlineArray<parameterValuesCount, Parameters<Parameter>>
    ) {
        self.destinationPortal = destinationPortal
        self.sourcePreparedStatement = sourcePreparedStatement
        self.trailingParameterFormatCodes = trailingParameterFormatCodes
        self.parameters = parameters
    }
}

// MARK: Parameter
extension PostgresBindMessage {
    public struct Parameters<each T: Sendable>: Sendable {
        public var values:(repeat each T)

        public init(_ values: (repeat each T)) {
            self.values = values
        }
    }
    public struct Parameter: Sendable {
        public var resultColumnFormatCode:Int16

        public init(resultColumnFormatCode: Int16) {
            self.resultColumnFormatCode = resultColumnFormatCode
        }
    }
}

// MARK: Payload
extension PostgresBindMessage {
    @inlinable
    public func payload() -> ByteBuffer {
        // TODO: implement
        return ByteBuffer(capacity: 0)
    }
}

// MARK: Write
extension PostgresBindMessage {
    @inlinable
    public func write<Connection: PostgresConnectionProtocol & ~Copyable>(
        to connection: borrowing Connection
    ) async throws {
        try await connection.writeBuffer(payload())
    }
}