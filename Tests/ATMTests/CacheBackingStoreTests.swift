import Testing

import ATM

struct CacheBackingStoreTests {
    @Test func readAndWrite() throws {
        let cache = CacheBackingStore<String, String>()
		
		#expect(cache.read("Korben") == nil)
		
		cache.write("Korben", "Dallas")
		#expect(cache.read("Korben") == "Dallas")
    }
}
