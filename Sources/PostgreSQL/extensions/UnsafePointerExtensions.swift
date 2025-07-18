
import SwiftDatabaseBlueprint

extension ByteBuffer {
    @inlinable
    public func writePostgresMessageHeader(
        type: UInt8,
        capacity: Int,
        to index: inout Int
    ) {
        self[index] = type
        index += 1
        writeIntBigEndian(Int32(capacity - 1), to: &index)
    }
}