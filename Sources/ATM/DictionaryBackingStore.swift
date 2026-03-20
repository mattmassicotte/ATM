import Foundation

/// A simple Swift dictionary-based store.
///
/// - note: This type will grow forever without manually management and ignores cost values.
public struct DictionaryBackingStore<Key: Hashable, Value>: BackingStore {
	private var internalCache = Dictionary<Key, CacheEntry<Value>>()

	public init() {
	}

	public func read(_ key: Key) -> Value? {
		internalCache[key]?.value
	}

	public func readEntry(_ key: Key) -> CacheEntry<Value>? {
		internalCache[key]
	}

	public mutating func write(_ key: Key, _ value: Value?, cost: Int) {
		guard let value else {
			self.internalCache[key] = nil
			return
		}

		internalCache[key] = CacheEntry(value: value, cost: cost)
	}
}
