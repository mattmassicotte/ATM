public actor SendableCache<Key: Hashable & Sendable, Value: Sendable> {
	private var cache: AsynchronousCache<Key, Value>
	
	public init(levels: [AsynchronousCache<Key, Value>.CacheLevel]) {
		self.cache = AsynchronousCache(levels: levels)
	}
	
	public init(writePolicy: WritePolicy, store: any AsyncBackingStore<Key, Value>) {
		self.init(levels: [.async(writePolicy, store)])
	}
	
	public init(writePolicy: WritePolicy, store: any BackingStore<Key, Value>) {
		self.init(levels: [.sync(writePolicy, store)])
	}
	
	public func read(_ key: Key) async -> Value? {
		await cache.read(key)
	}
	
	public func write(_ key: Key, _ value: Value?) async {
		var cacheCopy = cache
		
		await cacheCopy.write(key, value, actor: self)
		
		self.cache = cacheCopy
	}
}

extension SendableCache: AsyncBackingStore {
	public func read(_ key: Key, actor: isolated (any Actor)?) async -> Value? {
		await read(key)
	}
	
	public func write(_ key: Key, _ value: Value?, actor: isolated (any Actor)?) async {
		await write(key, value)
	}
}
