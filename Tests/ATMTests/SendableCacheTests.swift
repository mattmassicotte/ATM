import Testing

import ATM

struct SendableCacheTests {
	@Test func sendableReadAndWrite() async throws {
		let cache = SendableCache<String, String>(
			writePolicy: .writeThrough,
			store: DictionaryBackingStore()
		)
		
		#expect(await cache["korben"] == nil)
		
		await cache.write("korben", "dallas")
		#expect(await cache["korben"] == "dallas")
		
		await cache.write("korben", nil)
		#expect(await cache["korben"] == nil)
	}
}
