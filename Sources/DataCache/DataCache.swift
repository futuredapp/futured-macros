//
//  DataCache.swift
//  FuturedMacros
//
//  Created by Mikoláš Stuchlík on 13.01.2025.
//

public protocol VersionedDataCache {
    associatedtype _Versions: Hashable

    func makeSubscriber(predicate: @escaping (_ oldValue: _Versions, _ newValue: _Versions) -> Bool) -> AsyncStream<Self>
    func applyChanges(during block: () -> Void)
}

public final class SubscriptionBox<C: VersionedDataCache> {
    public init(
        initialVersion: C._Versions,
        predicate: @escaping (_ oldValue: C._Versions, _ newValue: C._Versions) -> Bool
    ) {
        self.initialVersion = initialVersion
        self.predicate = predicate
    }

    private var initialVersion: C._Versions
    private var predicate: (_ oldValue: C._Versions, _ newValue: C._Versions) -> Bool

    public var yeald: ((C) -> Void)!

    public func responds(to newVersion: C._Versions) -> Bool {
        defer {
            initialVersion = newVersion
        }
        return predicate(initialVersion, newVersion)
    }
}

public protocol ProxyObject<Ref> {
    associatedtype Ref: AnyObject
    init(ref: Ref)
}

public protocol ProxySettable {
    associatedtype Proxy: ProxyObject<Self>
}

public extension ProxySettable where Self: VersionedDataCache {
    func withTransaction(in block: (Proxy) -> Void) {
        self.applyChanges {
            block(Proxy(ref: self))
        }
    }
}

@attached(member, names: named(_version), named(_subscribtions), named(makeSubscriber), named(applyChanges), named(_Versions))
@attached(memberAttribute)
@attached(extension, conformances: VersionedDataCache)
public macro DataCache() = #externalMacro(module: "DataCacheMacros",type: "DataCacheMacro")

@attached(extension, conformances: ProxySettable)
public macro ProxySetter() = #externalMacro(module: "DataCacheMacros",type: "ProxySetterMacro")

@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(`_`))
public macro VersionedProperty() = #externalMacro(module: "DataCacheMacros", type: "VersionedPropertyMacro")

@freestanding(expression)
public macro cacheSubscribtion<T: VersionedDataCache, each P>(on: T, properties: repeat KeyPath<T, each P>) -> AsyncStream<T> = #externalMacro(
    module: "DataCacheMacros",
    type: "CacheSubscriptionMacro"
)
