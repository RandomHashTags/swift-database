
public enum DatabaseStorageMethod: Sendable {
    /// The database is stored on a physical device.
    case device

    /// The database is stored in heap/stack memory.
    case memory
}