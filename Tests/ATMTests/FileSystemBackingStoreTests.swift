import Foundation
import Testing

import ATM

@Suite(.serialized)
struct FileSystemBackingStoreTests {
	let url: URL

	init() throws {
		self.url = FileManager.default.temporaryDirectory.appendingPathComponent("atm-cache", isDirectory: true)

		try? FileManager.default.removeItem(at: url)
	}

	@Test func readAndWrite() throws {
		var store = try FileSystemBackingStore<String, String>(url: url)

		#expect(store.read("Korben") == nil)

		store.write("Korben", "Dallas")
		#expect(store.read("Korben") == "Dallas")
		#expect(FileManager.default.fileExists(atPath: url.appendingPathComponent("Korben").path))
	}

	@Test func errorReporting() async throws {
		var store = try FileSystemBackingStore<String, String>(
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

	@Test func unreadableExistingEntry() async throws {
		var store = try FileSystemBackingStore<String, String>(
			url: url
		)

		let keyURL = store.url(for: "Korben")

		// write some empty data here
		try Data().write(to: keyURL)

		await confirmation { confirmation in
			store.errorHandler = {
				#expect($0 is DecodingError)
				confirmation.confirm()
			}

			// this should fail
			#expect(store.read("Korben") == nil)

			// overriding should be possible
			store.write("Korben", "Dallas")
			#expect(store.read("Korben") == "Dallas")
		}
	}

	@Test func ageAttribute() async throws {
		var store = try FileSystemBackingStore<String, String>(url: url)

		#expect(store.read("Korben") == nil)

		store.write("Korben", "Dallas")

		try await Task.sleep(for: .milliseconds(1200))

		let entry = try #require(store.readEntry("Korben"))

		#expect(entry.age >= 1)
	}
}
