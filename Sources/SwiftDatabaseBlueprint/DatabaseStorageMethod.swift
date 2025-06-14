
public enum DatabaseStorageMethod: Sendable {
    /// The database is stored on a physical device.
    case device(address: String, port: UInt16)

    /// The database is stored in heap/stack memory.
    case memory
}