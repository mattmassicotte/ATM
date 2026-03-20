public struct AsynchronousCache<Key: Hashable, Value> {
	public enum CacheLevel: AsyncBackingStore {
		case sync(WritePolicy, EvictionPolicy, any BackingStore<Key, Value>)
		case async(WritePolicy, EvictionPolicy, any AsyncBackingStore<Key, Value>)

		public static func writeThrough(_ store: any BackingStore<Key, Value>) -> CacheLevel {
			.sync(.writeThrough, .none, store)
		}
		
		public static func writeBack(_ store: any BackingStore<Key, Value>) -> CacheLevel {
			.sync(.writeBack, .none, store)
		}
		
		public static func writeThrough(_ store: any AsyncBackingStore<Key, Value>) -> CacheLevel {
			.async(.writeThrough, .none, store)
		}
		
		public static func writeBack(_ store: any AsyncBackingStore<Key, Value>) -> CacheLevel {
			.async(.writeBack, .none, store)
		}

		public var writePolicy: WritePolicy {
			switch self {
			case .async(let policy, _, _):
				policy
			case .sync(let policy, _, _):
				policy
			}
		}

		public var evictionPolicy: EvictionPolicy {
			switch self {
			case .async(_, let policy, _):
				policy
			case .sync(_, let policy, _):
				policy
			}
		}

		public mutating func readEntry(_ key: Key) async -> CacheEntry<Value>? {
			switch self {
			case .async(let writePolicy, let evictionPolicy, var store):
				let entry = await store.readEntry(key)

				self = .async(writePolicy, evictionPolicy, store)

				return entry
			case .sync(let writePolicy, let evictionPolicy, var store):
				let entry = store.readEntry(key)

				self = .sync(writePolicy, evictionPolicy, store)

				return entry
			}
		}

		public mutating func write(_ key: Key, _ value: Value?, cost: Int) async {
			switch self {
			case .async(let writePolicy, let evictionPolicy, var store):
				await store.write(key, value, cost: cost)

				self = .async(writePolicy, evictionPolicy, store)
			case .sync(let writePolicy, let evictionPolicy, var store):
				store.write(key, value, cost: cost)

				self = .sync(writePolicy, evictionPolicy, store)
			}
		}
	}
	
	public var levels: [CacheLevel]

	public init(levels: [CacheLevel]) {
		self.levels = levels
	}
	
	public init(writePolicy: WritePolicy, evictionPolicy: EvictionPolicy = .none, store: any AsyncBackingStore<Key, Value>) {
		self.levels = [.async(writePolicy, evictionPolicy, store)]
	}
	
	public init(writePolicy: WritePolicy, evictionPolicy: EvictionPolicy = .none, store: any BackingStore<Key, Value>) {
		self.levels = [.sync(writePolicy, evictionPolicy, store)]
	}
}

extension AsynchronousCache: AsyncBackingStore {
	public mutating func readEntry(_ key: Key) async -> CacheEntry<Value>? {
		for i in 0..<levels.count {
			guard let entry = await levels[i].readEntry(key) else {
				continue
			}

			switch levels[i].evictionPolicy {
			case .none:
				return entry
			case .age(let maxAge):
				if entry.age >= maxAge {
					await levels[i].write(key, nil)
					return nil
				}

				return entry
			}
		}

		return nil

	}
	
	public mutating func write(_ key: Key, _ value: Value?, cost: Int) async {
		for i in 0..<levels.count {
			await levels[i].write(key, value, cost: cost)

			switch levels[i].writePolicy {
			case .writeBack:
				return
			case .writeThrough:
				continue
			}
		}
	}
}
