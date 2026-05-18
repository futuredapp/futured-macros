@_exported import ProxyMembers

/// Generates the boilerplate of a `CacheProjection`-conforming struct: the `state`
/// property, the `@ProxyMembers var data` storage, the `empty(state:)` factory, and
/// the `CacheProjection` conformance extension.
///
/// Apply to a `struct` that already has the `@dynamicMemberLookup` attribute. The
/// `state:` and `data:` arguments name the projection's State and Data types as
/// metatypes — both are required, no defaults.
///
/// ```swift
/// @CacheProjection(state: ComponentState.self, data: HomeData.self)
/// @dynamicMemberLookup
/// nonisolated struct HomeCacheProjection {
///     static func data(from cache: DataCacheModel) -> Self? { ... }
/// }
/// ```
///
/// Expands to (additions marked with comments):
///
/// ```swift
/// @dynamicMemberLookup
/// nonisolated struct HomeCacheProjection {
///     static func data(from cache: DataCacheModel) -> Self? { ... }
///
///     var state: ComponentState                                // ← generated
///     @ProxyMembers var data: HomeData                         // ← generated
///
///     static func empty(state: ComponentState) -> Self {       // ← generated
///         Self(state: state, data: .mock)
///     }
/// }
///
/// extension HomeCacheProjection: CacheProjection {}            // ← generated
/// ```
///
/// The emitted `@ProxyMembers var data: ...` is itself a macro invocation; Swift's
/// macro expansion is iterative, so on the next pass `@ProxyMembers` synthesizes
/// the `subscript(dynamicMember:)` accessor on the struct.
///
/// - Important: The Data type must conform to `Mockable` (`static var mock: Self`).
///   This is not enforceable as a generic constraint at the macro declaration
///   (`Mockable` is project-local), so a non-conforming Data type surfaces as a
///   `Type '...' has no member 'mock'` compile error at the use site.
///
/// - Important: Apply `@dynamicMemberLookup` to the struct yourself — macros cannot
///   annotate the host declaration.
@attached(member, names: named(state), named(data), named(empty(state:)))
@attached(extension, names: arbitrary)
public macro CacheProjection<State, Data>(
    state: State.Type,
    data: Data.Type
) = #externalMacro(module: "CacheProjectionMacros", type: "CacheProjectionMacro")
