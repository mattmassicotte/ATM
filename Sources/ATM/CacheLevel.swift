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
