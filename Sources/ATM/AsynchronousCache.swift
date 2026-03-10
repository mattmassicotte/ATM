public struct AsynchronousCache<Key: Hashable, Value> {
	public enum CacheLevel {
		case sync(WritePolicy, any BackingStore<Key, Value>)
		case async(WritePolicy, any AsyncBackingStore<Key, Value>)
		
		public static func writeThrough(_ store: any BackingStore<Key, Value>) -> CacheLevel {
			.sync(.writeThrough, store)
		}
		
		public static func writeBack(_ store: any BackingStore<Key, Value>) -> CacheLevel {
			.sync(.writeBack, store)
		}
		
		public static func writeThrough(_ store: any AsyncBackingStore<Key, Value>) -> CacheLevel {
			.async(.writeThrough, store)
		}
		
		public static func writeBack(_ store: any AsyncBackingStore<Key, Value>) -> CacheLevel {
			.async(.writeBack, store)
		}
	}
	
	public var levels: [CacheLevel]

	public init(levels: [CacheLevel]) {
		self.levels = levels
	}
	
	public init(writePolicy: WritePolicy, store: any AsyncBackingStore<Key, Value>) {
		self.levels = [.async(writePolicy, store)]
	}
	
	public init(writePolicy: WritePolicy, store: any BackingStore<Key, Value>) {
		self.levels = [.sync(writePolicy, store)]
	}
}

extension AsynchronousCache: AsyncBackingStore {
	public func read(_ key: Key) async -> Value? {
		for level in levels {
			switch level {
			case let .sync(_, store):
				if let value = store.read(key) {
					return value
				}
			case let .async(_, store):
				if let value = await store.read(key) {
					return value
				}
			}
		}
		
		return nil
	}
	
	public mutating func write(_ key: Key, _ value: Value?) async {
		guard let level = levels.first else {
			return
		}
		
		switch level {
		case .sync(let policy, var store):
			store.write(key, value)
			levels[0] = .sync(policy, store)
		case .async(let policy, var store):
			await store.write(key, value)
			levels[0] = .async(policy, store)
		}
	}
}
