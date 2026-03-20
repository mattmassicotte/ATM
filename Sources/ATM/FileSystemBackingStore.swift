import Foundation

/// A simple store backed by ``FileManager``.
public struct FileSystemBackingStore<Key: Hashable, Value: Codable>: BackingStore {
	public typealias Encoder = (CacheEntry<Value>) throws -> Data
	public typealias Decoder = (Data) throws -> CacheEntry<Value>
	public typealias KeyEncoder = (Key) -> String

	private let url: URL
	private let encoder: Encoder
	private let decoder: Decoder
	private let keyEncoder: KeyEncoder
	public var errorHandler: (any Error) -> Void = { _ in }

	public init(
		url: URL,
		encoder: @escaping Encoder,
		decoder: @escaping Decoder,
		keyEncoder: @escaping KeyEncoder
	) throws {
		self.url = url
		self.encoder = encoder
		self.decoder = decoder
		self.keyEncoder = keyEncoder

		try createDirectoryIfNeeded()
	}

	public func url(for key: Key) -> URL {
		let name = keyEncoder(key)

		return url.appendingPathComponent(name, isDirectory: false)
	}

	private func createDirectoryIfNeeded() throws {
		if FileManager.default.fileExists(atPath: url.path) == false {
			try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
		}
	}

	public func readEntry(_ key: Key) -> CacheEntry<Value>? {
		do {
			let keyURL = url(for: key)
			let data = try Data(contentsOf: keyURL)

			let entry = try decoder(data)

			return entry
		} catch {
			errorHandler(error)

			return nil
		}
	}

	public func write(_ key: Key, _ value: Value?, cost: Int) {
		do {
			let keyURL = url(for: key)

			guard let value else {
				if FileManager.default.fileExists(atPath: keyURL.path) {
					try FileManager.default.removeItem(at: keyURL)
				}

				return
			}

			let container = CacheEntry(value: value, cost: cost)
			let data = try encoder(container)
			try data.write(to: keyURL)
		} catch {
			errorHandler(error)
		}
	}
}

extension FileSystemBackingStore {
	/// Creates an instance that uses `JSONEncoder` and `JSONDecoder` for serialization.
	public init(
		url: URL,
		keyEncoder: @escaping KeyEncoder
	) throws {
		let jsonEncoder = JSONEncoder()
		let jsonDecoder = JSONDecoder()

		try self.init(
			url: url,
			encoder: { try jsonEncoder.encode($0) },
			decoder: { try jsonDecoder.decode(CacheEntry<Value>.self, from: $0) },
			keyEncoder: keyEncoder
		)
	}
}

extension FileSystemBackingStore where Key: CustomStringConvertible {
	/// Creates an instance that uses the key's description as the on-disk file name.
	public init(
		url: URL,
		encoder: @escaping Encoder,
		decoder: @escaping Decoder
	) throws {
		try self.init(
			url: url,
			encoder: encoder,
			decoder: decoder,
			keyEncoder: { $0.description }
		)
	}

	/// Creates an instance that uses `JSONEncoder` and `JSONDecoder` for serialization.
	public init(
		url: URL
	) throws {
		let jsonEncoder = JSONEncoder()
		let jsonDecoder = JSONDecoder()

		try self.init(
			url: url,
			encoder: { try jsonEncoder.encode($0) },
			decoder: { try jsonDecoder.decode(CacheEntry<Value>.self, from: $0) }
		)
	}
}
