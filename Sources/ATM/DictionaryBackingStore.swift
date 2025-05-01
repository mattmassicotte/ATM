import Foundation

public struct DictionaryBackingStore<Key: Hashable, Value>: BackingStore {
	private var internalCache = Dictionary<Key, Value>()
	
	public init() {
	}
	
	public func read(_ key: Key) -> Value? {
		internalCache[key]
	}
	
	public mutating func write(_ key: Key, _ value: Value?) {
		internalCache[key] = value
	}
}
