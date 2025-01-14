//
//  DataCache.swift
//  FuturedMacros
//
//  Created by Mikoláš Stuchlík on 13.01.2025.
//

public protocol VersionedDataCache {
    associatedtype __Versions
}

@attached(member, names: arbitrary)
@attached(memberAttribute)
@attached(extension, conformances: VersionedDataCache)
public macro DataCache() = #externalMacro(module: "DataCacheMacros",type: "DataCacheMacro")

@freestanding(expression)
public macro cacheSubscribtion<T: __Versions, each P>(on: T, properties: repeat KeyPath<T, each P>) -> AsyncStream<T> = #externalMacro(
    module: "DataCacheMacros",
    type: "CacheSubscriptionMacro"
)
