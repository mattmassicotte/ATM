/// A synchronous cache backing store.
public protocol BackingStore<Key, Value> {
	associatedtype Key: Hashable
	associatedtype Value
	
	func read(_ key: Key) -> Value?
	mutating func write(_ key: Key, _ value: Value?)
}

/// An asynchronous cache backing store.
public protocol AsyncBackingStore<Key, Value> {
	associatedtype Key: Hashable
	associatedtype Value
	
	func read(_ key: Key, actor: isolated (any Actor)?) async -> Value?
	mutating func write(_ key: Key, _ value: Value?, actor: isolated (any Actor)?) async
}

/// Defines how data written to the cache is propagated to its backing stores.
public enum WritePolicy {
	/// Values are written to the cache and subsequent level immediately.
	case writeThrough
	/// Values are only written to the cache immediately.
	case writeBack
}

extension BackingStore {
	public subscript(_ key: Key) -> Value? {
		get { read(key) }
		set { write(key, newValue) }
	}
}

extension AsyncBackingStore where Self: Actor, Key: Sendable, Value: Sendable {
	public subscript(_ key: Key) -> Value? {
		get async { await read(key, actor: self) }
	}
}
