//
//  DataCache.swift
//  FuturedMacros
//
//  Created by Mikoláš Stuchlík on 13.01.2025.
//

public protocol VersionedDataCache {
    associatedtype _Versions: Hashable
}

public final class SubscriptionBox<C: VersionedDataCache> {
    public init(
        initialVersion: C._Versions,
        continuation: AsyncStream<C>.Continuation,
        predicate: @escaping (_ oldValue: C._Versions, _ newValue: C._Versions) -> Bool
    ) {
        self.lastVersion = initialVersion
        self.yield = continuation.yield
        self.predicate = predicate
    }

    private let yield: (sending C) -> AsyncStream<C>.Continuation.YieldResult
    private let predicate: (_ oldValue: C._Versions, _ newValue: C._Versions) -> Bool
    private var lastVersion: C._Versions

    public func emmit(cache: C, ifDiffers newVersion: C._Versions) {
        defer {
            lastVersion = newVersion
        }
        if predicate(lastVersion, newVersion) {
            _ = yield(cache)
        }
    }
}

public protocol ProxyObject<Ref> {
    associatedtype Ref: AnyObject
}

public protocol ProxySettable {
    associatedtype Proxy: ProxyObject<Self>
}

@attached(member, names: named(_version), named(_subscribtions), named(makeSubscriber), named(applyChanges), named(_Versions))
@attached(memberAttribute)
@attached(extension, conformances: VersionedDataCache)
public macro DataCache<GA: GlobalActor>(isolation: GA.Type? = Optional<MainActor.Type>.none) = #externalMacro(
    module: "DataCacheMacros",
    type: "DataCacheMacro"
)

@attached(extension, conformances: ProxySettable, names: named(Proxy), named(withTransaction))
public macro ProxySetter<GA: GlobalActor>(isolation: GA.Type? = Optional<MainActor.Type>.none) = #externalMacro(
    module: "DataCacheMacros",
    type: "ProxySetterMacro"
)

@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(`_`))
public macro VersionedProperty() = #externalMacro(module: "DataCacheMacros", type: "VersionedPropertyMacro")

@freestanding(expression)
public macro cacheSubscribtion<T: VersionedDataCache, each P>(on: T, properties: repeat KeyPath<T, each P>) -> AsyncStream<T> = #externalMacro(
    module: "DataCacheMacros",
    type: "CacheSubscriptionMacro"
)
