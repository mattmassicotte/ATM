public struct SynchronousCache<Key: Hashable, Value> {
	public struct CacheLevel {
		public var writePolicy: WritePolicy
		public var store: any BackingStore<Key, Value>
		
		public init(writePolicy: WritePolicy, store: any BackingStore<Key, Value>) {
			self.writePolicy = writePolicy
			self.store = store
		}
		
		public static func writeThrough(_ store: any BackingStore<Key, Value>) -> CacheLevel {
			CacheLevel(writePolicy: .writeThrough, store: store)
		}
		
		public static func writeBack(_ store: any BackingStore<Key, Value>) -> CacheLevel {
			CacheLevel(writePolicy: .writeBack, store: store)
		}
	}
	
	public var levels: [CacheLevel]

	public init(levels: [CacheLevel]) {
		self.levels = levels
	}
	
	public init(writePolicy: WritePolicy, store: any BackingStore<Key, Value>) {
		self.levels = [CacheLevel(writePolicy: writePolicy, store: store)]
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
	
	public mutating func write(_ key: Key, _ value: Value?, cost: Int) {
		for i in 0..<levels.count {
			levels[i].store.write(key, value, cost: cost)

			switch levels[i].writePolicy {
			case .writeBack:
				return
			case .writeThrough:
				continue
			}
		}
	}
}
