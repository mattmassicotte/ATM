import Foundation

public struct CacheBackingStore<Key: Hashable, Value>: BackingStore {
	private final class Wrapper<T> {
		let value: T
		
		init(value: T) {
			self.value = value
		}
	}
	
	private let internalCache = NSCache<Wrapper<Key>, Wrapper<Value>>()
	
	public init() {
	}
	
	public func read(_ key: Key) -> Value? {
		internalCache.object(forKey: Wrapper(value: key))?.value
	}
	
	public func write(_ key: Key, _ value: Value?) {
		let key = Wrapper(value: key)
		
		guard let value else {
			internalCache.removeObject(forKey: key)
			return
		}
		
		internalCache.setObject(Wrapper(value: value), forKey: key)
	}
}
