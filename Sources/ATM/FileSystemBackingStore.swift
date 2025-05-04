import Foundation

/// A simple store backed by ``FileManager``.
public struct FileSystemBackingStore<Value: Codable>: BackingStore {

	public typealias Key = String

	private let directoryName: String
	private let encoder: JSONEncoder
	private let decoder: JSONDecoder

	public init(
		directoryName: String,
		encoder: JSONEncoder = .init(),
		decoder: JSONDecoder = .init()
	) {
		self.directoryName = directoryName
		self.encoder = encoder
		self.decoder = decoder
	}

	public func read(_ key: Key) -> Value? {
		do {
			let fileURL = try FileManager.directoryAt(directoryName).appendingPathComponent(key as String)

			guard FileManager.default.fileExists(at: fileURL) else {
				return nil
			}

			let data = try Data(contentsOf: fileURL)
			return try decoder.decode(Value.self, from: data)
		} catch {
			// how do we handle errors?
			return nil
		}
	}

	public func write(_ key: Key, _ value: Value?) {
		do {
			let fileURL = try FileManager.directoryAt(directoryName).appendingPathComponent(key as String)

			guard let value else {
				if FileManager.default.fileExists(at: fileURL) {
					try FileManager.default.removeItem(at: fileURL)
				}
				return
			}

			let data = try encoder.encode(value)
			try data.write(to: fileURL)
		} catch {
			// how do we handle errors?
		}
	}
}


private extension FileManager {
	func fileExists(at url: URL) -> Bool {
		fileExists(atPath: url.path)
	}

	static func directoryAt(_ path: String) throws -> URL {
		let appSupportDirectory = try FileManager.default.url(
			for: .applicationSupportDirectory,
			in: .userDomainMask,
			appropriateFor: nil,
			create: true
		)

		let directoryPath = appSupportDirectory.appendingPathComponent(path, isDirectory: true)

		var isDirectory = ObjCBool(true)
		if !FileManager.default.fileExists(atPath: directoryPath.path, isDirectory: &isDirectory) {
			try FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: true)
		}

		return directoryPath
	}
}
