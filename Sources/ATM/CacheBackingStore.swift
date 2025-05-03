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
		let key: Key
		let value: Value
		
		init(_ value: Value, for key: Key) {
			self.key = key
			self.value = value
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
	
	public func read(_ key: Key) -> Value? {
		let keyObj = KeyObject(key)
		
		return internalCache.object(forKey: keyObj)?.value
	}
	
	public func write(_ key: Key, _ value: Value?) {
		let keyObj = KeyObject(key)
		
		guard let value else {
			internalCache.removeObject(forKey: keyObj)
			return
		}
		
		let valueObj = ValueObject(value, for: key)
		
		internalCache.setObject(valueObj, forKey: keyObj)
	}
}
