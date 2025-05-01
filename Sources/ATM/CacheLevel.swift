public protocol BackingStore<Key, Value> {
	associatedtype Key: Hashable
	associatedtype Value
	
	func read(_ key: Key) -> Value?
	mutating func write(_ key: Key, _ value: Value?)
}

public protocol AsyncBackingStore<Key, Value> {
	associatedtype Key: Hashable
	associatedtype Value
	
	func read(_ key: Key, actor: isolated (any Actor)?) async -> Value?
	mutating func write(_ key: Key, _ value: Value?, actor: isolated (any Actor)?) async
}

public enum WritePolicy {
	case writeThrough
	case writeBack
}

public struct CacheLevel<Key: Hashable, Value> {
	public var writePolicy: WritePolicy
	public var store: any BackingStore<Key, Value>
	
	public init(writePolicy: WritePolicy, store: any BackingStore<Key, Value>) {
		self.writePolicy = writePolicy
		self.store = store
	}
}

