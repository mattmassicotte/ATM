import Foundation

public struct CacheEntry<Value> {
	public let value: Value
	public let creationTime: Int
	public let cost: Int

	public init(value: Value, creationTime: Int, cost: Int) {
		self.value = value
		self.creationTime = creationTime
		self.cost = cost
	}

	public init(value: Value, cost: Int) {
		self.value = value
		self.creationTime = Int(Date().timeIntervalSince1970)
		self.cost = cost
	}

	public var age: Int {
		Int(Date().timeIntervalSince1970) - creationTime 
	}
}

extension CacheEntry: Equatable where Value: Equatable {}
extension CacheEntry: Hashable where Value: Hashable {}
extension CacheEntry: Sendable where Value: Sendable {}
extension CacheEntry: Encodable where Value: Encodable {}
extension CacheEntry: Decodable where Value: Decodable {}

/// A synchronous cache backing store.
public protocol BackingStore<Key, Value> {
	associatedtype Key: Hashable
	associatedtype Value

	mutating func readEntry(_ key: Key) -> CacheEntry<Value>?
	mutating func write(_ key: Key, _ value: Value?, cost: Int)
}

/// An asynchronous cache backing store.
public protocol AsyncBackingStore<Key, Value> {
	associatedtype Key: Hashable
	associatedtype Value
	
	mutating func readEntry(_ key: Key) async -> CacheEntry<Value>?
	mutating func write(_ key: Key, _ value: Value?, cost: Int) async
}

/// Defines how data written to the cache is propagated to its backing stores.
public enum WritePolicy {
	/// Values are written to the cache and subsequent level immediately.
	case writeThrough
	/// Values are only written to the cache immediately.
	case writeBack
}

public enum EvictionPolicy {
	// Values are never evicted
	case none

	// Age in seconds
	case age(Int)
}

extension BackingStore {
	public mutating func read(_ key: Key) -> Value? {
		readEntry(key)?.value
	}

	public mutating func write(_ key: Key, _ value: Value?) {
		write(key, value, cost: 0)
	}

	public subscript(_ key: Key) -> Value? {
		mutating get { read(key) }
		set { write(key, newValue) }
	}
}

extension AsyncBackingStore {
	public mutating func read(_ key: Key) async -> Value? {
		await readEntry(key)?.value
	}

	public mutating func write(_ key: Key, _ value: Value?) async {
		await write(key, value, cost: 0)
	}

	public subscript(_ key: Key) -> Value? {
		mutating get async { await read(key) }
	}
}
