import Foundation

/// A simple Swift dictionary-based store.
///
/// - note: This type will grow forever without manually management and ignores cost values.
public struct DictionaryBackingStore<Key: Hashable, Value>: BackingStore {
	private var internalCache = Dictionary<Key, Value>()
	
	public init() {
	}
	
	public func read(_ key: Key) -> Value? {
		internalCache[key]
	}
	
	public mutating func write(_ key: Key, _ value: Value?, cost: Int) {
		internalCache[key] = value
	}
}
