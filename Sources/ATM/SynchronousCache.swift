public struct SynchronousCache<Key: Hashable, Value> {
	public struct CacheLevel {
		public var writePolicy: WritePolicy
		public var evictionPolicy: EvictionPolicy
		public var store: any BackingStore<Key, Value>

		public init(writePolicy: WritePolicy, evictionPolicy: EvictionPolicy = .none, store: any BackingStore<Key, Value>) {
			self.writePolicy = writePolicy
			self.evictionPolicy = evictionPolicy
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
	
	public init(writePolicy: WritePolicy, evictionPolicy: EvictionPolicy = .none, store: any BackingStore<Key, Value>) {
		self.levels = [CacheLevel(writePolicy: writePolicy, evictionPolicy: evictionPolicy, store: store)]
	}
}

extension SynchronousCache: BackingStore {
	public mutating func readEntry(_ key: Key) -> CacheEntry<Value>? {
		for i in 0..<levels.count {
			guard let entry = levels[i].store.readEntry(key) else {
				continue
			}

			switch levels[i].evictionPolicy {
			case .none:
				return entry
			case .age(let maxAge):
				if entry.age >= maxAge {
					levels[i].store.write(key, nil)
					return nil
				}

				return entry
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
