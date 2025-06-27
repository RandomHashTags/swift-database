
public protocol AnyModel: SchemaProtocol, ~Copyable {
    static var table: String { get }
}