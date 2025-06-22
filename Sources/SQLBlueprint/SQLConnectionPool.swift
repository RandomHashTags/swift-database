
import SwiftDatabaseBlueprint

public actor SQLConnectionPool<T: SQLConnectionProtocol> { // TODO: make noncopyable?
    let storage:DatabaseStorageMethod
    var maxConnections:Int
    var available:[T]
    var waiting:[CheckedContinuation<T, Never>]
    
    public init(
        storage: DatabaseStorageMethod,
        maxConnections: Int
    ) {
        self.storage = storage
        self.maxConnections = maxConnections
        available = []
        available.reserveCapacity(maxConnections)
        waiting = []
    }
}

// MARK: Bulk establish connections
extension SQLConnectionPool {
    public func establishConnections(_ onLoad: ([T]) -> Void = { _ in }) async {
        shutdown()
        let storage = storage
        await withTaskGroup(of: T?.self) { group in
            for _ in 0..<maxConnections {
                group.addTask {
                    var connection = T()
                    do {
                        try await connection.establishConnection(storage: storage)
                        return connection
                    } catch {
                        // TODO: log and handle
                        return nil
                    }
                }
            }
            for await con in group {
                if let con {
                    available.append(con)
                }
            }
            onLoad(available)
        }
    }
}

// MARK: Aquire
extension SQLConnectionPool {
    public func aquire() async throws -> T {
        if let popped = available.popLast() {
            return popped
        }
        if available.count < maxConnections {
            var connection = T()
            try await connection.establishConnection(storage: storage)
            return connection
        }
        return await withCheckedContinuation { waiting.append($0) }
    }
}

// MARK: Release
extension SQLConnectionPool {
    public func release(_ connection: T) {
        available.append(connection)
        while !waiting.isEmpty && !available.isEmpty {
            let availableConnection = available.removeLast()
            let continuation = waiting.removeFirst()
            continuation.resume(returning: availableConnection)
        }
    }
}

// MARK: Shutdown
extension SQLConnectionPool {
    public func shutdown() {
        for connection in available {
            connection.shutdownConnection()
        }
        available.removeAll(keepingCapacity: true)
        waiting.removeAll(keepingCapacity: true)
    }
}

// MARK: Query
extension SQLConnectionPool {
    public func query(_ sql: String, _ closure: (T.RawMessage) async throws -> Void) async throws -> T.QueryMessage.ConcreteResponse {
        var connection = try await aquire()
        defer { release(connection) }
        return try await connection.query(unsafeSQL: sql)
    }
}