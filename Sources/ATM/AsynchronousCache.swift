public struct AsynchronousCache<Key: Hashable, Value> {
	public enum CacheLevel {
		case sync(WritePolicy, any BackingStore<Key, Value>)
		case async(WritePolicy, any AsyncBackingStore<Key, Value>)
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
	public func read(_ key: Key, actor: isolated (any Actor)? = #isolation) async -> Value? {
		for level in levels {
			switch level {
			case let .sync(_, store):
				if let value = store.read(key) {
					return value
				}
			case let .async(_, store):
				if let value = await store.read(key, actor: actor) {
					return value
				}
			}
		}
		
		return nil
	}
	
	public mutating func write(_ key: Key, _ value: Value?, actor: isolated (any Actor)? = #isolation) async {
		guard let level = levels.first else {
			return
		}
		
		switch level {
		case var .sync(policy, store):
			store.write(key, value)
			levels[0] = .sync(policy, store)
		case var .async(policy, store):
			await store.write(key, value, actor: actor)
			levels[0] = .async(policy, store)
		}
	}
}
