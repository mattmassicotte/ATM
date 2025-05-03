import Testing

import ATM

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
}
