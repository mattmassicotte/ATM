public struct SynchronousCache<Key: Hashable, Value> {
	public var levels: [CacheLevel<Key, Value>]

	public init(levels: [CacheLevel<Key, Value>]) {
		self.levels = levels
	}
	
	public init(writePolicy: WritePolicy, store: any BackingStore<Key, Value>) {
		self.levels = [.init(writePolicy: writePolicy, store: store)]
	}
}

extension SynchronousCache: BackingStore {
	public func read(_ key: Key) -> Value? {
		for level in levels {
			if let value = level.store.read(key) {
				return value
			}
		}
		
		return nil
	}
	
	public mutating func write(_ key: Key, _ value: Value?) {
		guard var level = levels.first else {
			return
		}
			
		level.store.write(key, value)
		
		levels[0] = level
	}
}

extension SynchronousCache {
	public subscript(_ key: Key) -> Value? {
		get {
			read(key)
		}
		set {
			write(key, newValue)
		}
	}
}
