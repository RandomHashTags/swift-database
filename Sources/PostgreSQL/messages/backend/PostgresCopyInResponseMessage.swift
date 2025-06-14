
import PostgreSQLBlueprint

extension PostgresRawMessage {
    /// Documentation: https://www.postgresql.org/docs/current/protocol-message-formats.html#PROTOCOL-MESSAGE-FORMATS-COPYINRESPONSE
    public struct CopyInResponse: PostgresCommandCompleteMessageProtocol {
        public var format:Int8
        public var columns:[Int16]

        public init(format: Int8, columns: [Int16]) {
            self.format = format
            self.columns = columns
        }
    }
}

// MARK: Parse
extension PostgresRawMessage.CopyInResponse {
    public static func parse(
        message: PostgresRawMessage,
        _ closure: (consuming Self) throws -> Void
    ) throws {
        guard message.type == .G else {
            throw PostgresError.copyInResponse("message type != .G")
        }
        let format:Int8 = message.body.loadUnalignedIntBigEndian(offset: 4)
        let numberOfColumns:Int16 = message.body.loadUnalignedIntBigEndian(offset: 5)
        var columns:[Int16] = []
        columns.reserveCapacity(Int(numberOfColumns))
        var offset = 7
        if numberOfColumns > 0 {
            for _ in 0..<numberOfColumns {
                columns.append(message.body.loadUnalignedIntBigEndian(offset: offset))
                offset += 2
            }
        }
        try closure(.init(format: format, columns: columns))
    }
}