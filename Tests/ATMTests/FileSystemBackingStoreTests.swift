import Foundation
import Testing

import ATM

@Suite
struct FileSystemBackingStoreTests {
	let url: URL

	init() throws {
		self.url = FileManager.default.temporaryDirectory.appendingPathComponent("atm-cache", isDirectory: true)

		try? FileManager.default.removeItem(at: url)
	}

	@Test func readAndWrite() throws {
		let store = try FileSystemBackingStore<String>(url: url)

		#expect(store.read("Korben") == nil)

		store.write("Korben", "Dallas")
		#expect(store.read("Korben") == "Dallas")
		#expect(FileManager.default.fileExists(atPath: url.appendingPathComponent("Korben").path))
	}

	@Test func errorReporting() async throws {
		var store = try FileSystemBackingStore<String>(
			url: url,
			encoder: { _ in throw CancellationError() },
			decoder: { _ in throw CancellationError() }
		)

		await confirmation { confirmation in
			store.errorHandler = {
				#expect($0 is CancellationError)
				confirmation.confirm()
			}

			store.write("Korben", "Dallas")
		}
	}
}
