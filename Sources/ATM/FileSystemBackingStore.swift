import Foundation

/// A simple store backed by ``FileManager``.
public struct FileSystemBackingStore<Value: Codable>: BackingStore {
	public typealias Key = String
	public typealias Encoder = (Value) throws -> Data
	public typealias Decoder = (Data) throws -> Value

	private let url: URL
	private let encoder: Encoder
	private let decoder: Decoder
	public var errorHandler: (any Error) -> Void = { _ in }

	public init(
		url: URL,
		encoder: @escaping Encoder,
		decoder: @escaping Decoder
	) throws {
		self.url = url
		self.encoder = encoder
		self.decoder = decoder

		try createDirectoryIfNeeded()
	}

	public func url(for key: Key) -> URL {
		url.appendingPathComponent(key, isDirectory: false)
	}

	private func createDirectoryIfNeeded() throws {
		if FileManager.default.fileExists(atPath: url.path) == false {
			try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
		}
	}

	public func read(_ key: Key) -> Value? {
		do {
			let keyURL = url(for: key)
			let data = try Data(contentsOf: keyURL)

			return try decoder(data)
		} catch {
			errorHandler(error)

			return nil
		}
	}

	public func write(_ key: Key, _ value: Value?) {
		do {
			let keyURL = url(for: key)

			guard let value else {
				if FileManager.default.fileExists(atPath: keyURL.path) {
					try FileManager.default.removeItem(at: keyURL)
				}

				return
			}

			let data = try encoder(value)
			try data.write(to: keyURL)
		} catch {
			errorHandler(error)
		}
	}
}

extension FileSystemBackingStore {
	public init(
		url: URL
	) throws {
		let jsonEncoder = JSONEncoder()
		let jsonDecoder = JSONDecoder()

		try self.init(
			url: url,
			encoder: { try jsonEncoder.encode($0) },
			decoder: { try jsonDecoder.decode(Value.self, from: $0) }
		)
	}
}
