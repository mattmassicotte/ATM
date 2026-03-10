import TaskGate

public actor SendableCache<Key: Hashable & Sendable, Value: Sendable> {
	private var cache: AsynchronousCache<Key, Value>
	private let gate = AsyncGate()

	public init(levels: [AsynchronousCache<Key, Value>.CacheLevel]) {
		self.cache = AsynchronousCache(levels: levels)
	}
	
	public init(writePolicy: WritePolicy, store: any AsyncBackingStore<Key, Value>) {
		self.init(levels: [.async(writePolicy, store)])
	}
	
	public init(writePolicy: WritePolicy, store: any BackingStore<Key, Value>) {
		self.init(levels: [.sync(writePolicy, store)])
	}
}

extension SendableCache: AsyncBackingStore {
	private func internalRead(_ key: Key) async -> Value? {
		await cache.read(key)
	}

	private func internalWrite(_ key: Key, _ value: Value?) async {
		await gate.withGate {
			var cacheCopy = cache

			await cacheCopy.write(key, value)

			self.cache = cacheCopy
		}
	}

	public nonisolated func read(_ key: Key) async -> Value? {
		await internalRead(key)
	}

	public nonisolated func write(_ key: Key, _ value: Value?) async {
		await internalWrite(key, value)
	}
}
