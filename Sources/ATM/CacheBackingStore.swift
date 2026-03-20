import Foundation

/// A store backed by NSCache.
public struct CacheBackingStore<Key: Hashable, Value>: BackingStore {
	private final class KeyObject: NSObject {
		let key: Key
		
		init(_ key: Key) {
			self.key = key
		}
		
		override var hash: Int {
			key.hashValue
		}

		override func isEqual(_ object: Any?) -> Bool {
			guard let keyObj = object as? KeyObject else {
				return false
			}

			return keyObj.key == key
		}
	}
	
	private final class ValueObject {
		let entry: CacheEntry<Value>

		init(value: Value, cost: Int) {
			self.entry = CacheEntry(value: value, cost: cost)
		}
	}
	
	private final class CacheDelegate: NSObject, NSCacheDelegate {
		var evictionHandler: ((ValueObject) -> Void)?
		
		func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
			guard
				let handler = evictionHandler,
				let wrapper = obj as? ValueObject
			else {
				return
			}
			
			handler(wrapper)
		}
	}
		
	private let internalCache = NSCache<KeyObject, ValueObject>()
	private let delegate = CacheDelegate()
	
	public init() {
		internalCache.delegate = delegate
		
		delegate.evictionHandler = handleEviction(of:)
	}
	
	private func handleEviction(of wrapper: ValueObject) {
		// should we do something here?
	}

	public func readEntry(_ key: Key) -> CacheEntry<Value>? {
		let keyObj = KeyObject(key)

		return internalCache.object(forKey: keyObj)?.entry
	}
	
	public func write(_ key: Key, _ value: Value?, cost: Int) {
		let keyObj = KeyObject(key)
		
		guard let value else {
			internalCache.removeObject(forKey: keyObj)
			return
		}
		
		let valueObj = ValueObject(value: value, cost: cost)

		internalCache.setObject(valueObj, forKey: keyObj, cost: cost)
	}
}
