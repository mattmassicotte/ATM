<div align="center">

[![Build Status][build status badge]][build status]
[![Platforms][platforms badge]][platforms]
[![Documentation][documentation badge]][documentation]
[![Matrix][matrix badge]][matrix]

</div>

# ATM

Where you get your cache

- Fully synchronous or mixed sync/async caches
- Concurrency-friendly API
- Multi-level support with write policies per level
- Backing stores for `Dictionary`, `NSCache`, and the local disk

> [!WARNING]
> still working out some implementation details
 
## Integration

```swift
dependencies: [
    .package(url: "https://github.com/mattmassicotte/ATM", branch: "main")
]
```

## Usage

Fully synchronous cache with a single backing store.

```swift
var cache = SynchronousCache<String, String>(
    writePolicy: .writeThrough,
    store: DictionaryBackingStore()
)

cache["korben"] = "dallas"
print(cache["korben"]) // "dallas"
```

Multi-level cache:

```swift
var cache = SynchronousCache<String, String>(
    levels: [
        .writeThrough(DictionaryBackingStore()),
        .writeThrough(CacheBackingStore()),
        .writeThrough(FileSystemBackingStore(url: localURL))
    ]
)
```

The `AsynchronousCache` supports both synchronous and asynchronous cache levels, but exposes an asynchronous interface.

```swift
var cache = AsynchronousCache<String, String>(
    writePolicy: .writeThrough,
    store: DictionaryBackingStore()
)

await cache.write("korben", "dallas")
print(await cache.read("korben")) // "dallas"
```

Both `SynchronousCache` and `AsynchronousCache` are non-Sendable.

There's a cool library called [LRUCache](https://github.com/nicklockwood/LRUCache) that could be useful here. This is how you'd incorporate it:

```swift
import LRUCache
import ATM

struct LRUCacheStore<Key: Hashable & Sendable, Value: Sendable>: BackingStore {
    private let lruCache = LRUCache<Key, CacheEntry<Value>>(clearsOnMemoryPressure: true)

    public func readEntry(_ key: Key) -> CacheEntry<Value>? {
        lruCache.value(forKey: key)
    }

    public func write(_ key: Key, _ value: Value?, cost: Int) {
        guard let value else {
            lruCache.removeValue(forKey: key)
            return
        }

        let entry = CacheEntry(value: value, cost: cost)

        lruCache.setValue(entry, forKey: key, cost: cost)
    }
}

var cache = SynchronousCache<String, String>(
    writePolicy: .writeThrough,
    store: LRUCacheStore<String, Int>()
)
```

## Contributing and Collaboration

I would love to hear from you! Issues or pull requests work great. Both a [Matrix space][matrix] and [Discord][discord] are available for live help, but I have a strong bias towards answering in the form of documentation. You can also find me on [the web](https://www.massicotte.org).

I prefer collaboration, and would love to find ways to work together if you have a similar project.

I prefer indentation with tabs for improved accessibility. But, I'd rather you use the system you want and make a PR than hesitate because of whitespace.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).

[build status]: https://github.com/mattmassicotte/ATM/actions
[build status badge]: https://github.com/mattmassicotte/ATM/workflows/CI/badge.svg
[platforms]: https://swiftpackageindex.com/mattmassicotte/ATM
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmattmassicotte%2FATM%2Fbadge%3Ftype%3Dplatforms
[documentation]: https://swiftpackageindex.com/mattmassicotte/ATM/main/documentation
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue
[matrix]: https://matrix.to/#/%23chimehq%3Amatrix.org
[matrix badge]: https://img.shields.io/matrix/chimehq%3Amatrix.org?label=Matrix
[discord]: https://discord.gg/esFpX6sErJ
