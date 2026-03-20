import Foundation

import Testing

import ATM

class ReferenceStore<Store: BackingStore>: BackingStore {
	private(set) var wrapped: Store

	init(_ wrapped: Store) {
		self.wrapped = wrapped
	}

	func readEntry(_ key: Store.Key) -> CacheEntry<Store.Value>? {
		wrapped.readEntry(key)
	}

	func write(_ key: Store.Key, _ value: Store.Value?, cost: Int) {
		wrapped.write(key, value, cost: cost)
	}
}

struct ATMTests {
	@Test func readAndWriteDictionaryStore() throws {
		var cache = SynchronousCache<String, Int>(
			writePolicy: .writeThrough,
			store: DictionaryBackingStore()
		)
		
		#expect(cache["korben"] == nil)
		
		cache["korben"] = 45
		#expect(cache["korben"] == 45)
		
		cache["korben"] = nil
		#expect(cache["korben"] == nil)
	}

	@Test func evictionWithDictionaryStore() async throws {
		var cache = SynchronousCache<String, Int>(
			writePolicy: .writeThrough,
			evictionPolicy: EvictionPolicy.age(1),
			store: DictionaryBackingStore()
		)

		cache["korben"] = 45
		#expect(cache["korben"] == 45)

		try await Task.sleep(for: .milliseconds(1200))

		#expect(cache["korben"] == nil)
	}

	@Test func multilevelStore() throws {
		var cache = SynchronousCache<String, Int>(
			levels: [
				.writeThrough(DictionaryBackingStore()),
				.writeThrough(CacheBackingStore()),
			]
		)
		
		#expect(cache["korben"] == nil)
		
		cache["korben"] = 45
		#expect(cache["korben"] == 45)

		cache["korben"] = nil
		#expect(cache["korben"] == nil)
	}

	@Test func synchronousWriteThroughPolicy() throws {
		var level0 = ReferenceStore(DictionaryBackingStore<String, Int>())
		var level1 = ReferenceStore(DictionaryBackingStore<String, Int>())
		var level2 = ReferenceStore(DictionaryBackingStore<String, Int>())

		var cache = SynchronousCache<String, Int>(
			levels: [
				.writeThrough(level0),
				.writeThrough(level1),
				.writeThrough(level2),
			]
		)

		#expect(cache["korben"] == nil)

		cache["korben"] = 45
		#expect(cache["korben"] == 45)
		#expect(level0["korben"] == 45)
		#expect(level1["korben"] == 45)
		#expect(level2["korben"] == 45)

		cache["korben"] = nil
		#expect(cache["korben"] == nil)
		#expect(level0["korben"] == nil)
		#expect(level1["korben"] == nil)
		#expect(level2["korben"] == nil)
	}

	@Test func synchronousWriteBackPolicy() throws {
		var level0 = ReferenceStore(DictionaryBackingStore<String, Int>())
		var level1 = ReferenceStore(DictionaryBackingStore<String, Int>())
		var level2 = ReferenceStore(DictionaryBackingStore<String, Int>())

		var cache = SynchronousCache<String, Int>(
			levels: [
				.writeThrough(level0),
				.writeBack(level1),
				.writeBack(level2), // technically meaningless as the last level
			]
		)

		#expect(cache["korben"] == nil)

		cache["korben"] = 45
		#expect(cache["korben"] == 45)
		#expect(level0["korben"] == 45)
		#expect(level1["korben"] == 45)
		#expect(level2["korben"] == nil)

		cache["korben"] = nil
		#expect(cache["korben"] == nil)
		#expect(level0["korben"] == nil)
		#expect(level1["korben"] == nil)
		#expect(level2["korben"] == nil)
	}
}

extension ATMTests {
	@Test func readAndWriteDictionaryAsyncStore() async throws {
		var cache = AsynchronousCache<String, Int>(
			writePolicy: .writeThrough,
			store: DictionaryBackingStore()
		)
		
		#expect(await cache.read("korben") == nil)
		
		await cache.write("korben", 45)
		#expect(await cache.read("korben") == 45)
		
		await cache.write("korben", nil)
		#expect(await cache.read("korben") == nil)
	}
	
	@Test func multilevelAsyncStore() async throws {
		var cache = AsynchronousCache<String, String>(
			levels: [
				.writeThrough(DictionaryBackingStore()),
				.writeThrough(CacheBackingStore()),
			]
		)
		
		#expect(await cache.read("korben") == nil)
		
		await cache.write("korben", "dallas")
		#expect(await cache.read("korben") == "dallas")
		
		await cache.write("korben", nil)
		#expect(await cache.read("korben") == nil)
	}

	@Test func asynchronousWriteThroughPolicy() async throws {
		var level0 = ReferenceStore(DictionaryBackingStore<String, Int>())
		var level1 = ReferenceStore(DictionaryBackingStore<String, Int>())
		var level2 = ReferenceStore(DictionaryBackingStore<String, Int>())

		var cache = AsynchronousCache<String, Int>(
			levels: [
				.writeThrough(level0),
				.writeThrough(level1),
				.writeThrough(level2),
			]
		)

		#expect(await cache["korben"] == nil)

		await cache.write("korben", 45)
		#expect(await cache["korben"] == 45)
		#expect(level0["korben"] == 45)
		#expect(level1["korben"] == 45)
		#expect(level2["korben"] == 45)

		await cache.write("korben", nil)
		#expect(await cache["korben"] == nil)
		#expect(level0["korben"] == nil)
		#expect(level1["korben"] == nil)
		#expect(level2["korben"] == nil)
	}

	@Test func asynchronousWriteBackPolicy() async throws {
		var level0 = ReferenceStore(DictionaryBackingStore<String, Int>())
		var level1 = ReferenceStore(DictionaryBackingStore<String, Int>())
		var level2 = ReferenceStore(DictionaryBackingStore<String, Int>())

		var cache = AsynchronousCache<String, Int>(
			levels: [
				.writeThrough(level0),
				.writeBack(level1),
				.writeBack(level2), // technically meaningless as the last level
			]
		)

		#expect(await cache["korben"] == nil)

		await cache.write("korben", 45)
		#expect(await cache["korben"] == 45)
		#expect(level0["korben"] == 45)
		#expect(level1["korben"] == 45)
		#expect(level2["korben"] == nil)

		await cache.write("korben", nil)
		#expect(await cache["korben"] == nil)
		#expect(level0["korben"] == nil)
		#expect(level1["korben"] == nil)
		#expect(level2["korben"] == nil)
	}
}
