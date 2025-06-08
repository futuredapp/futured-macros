/// Exposes members of the attached property on the enclosing type by generating the
/// necessary `subscript(dynamicMember:)` implementations.
///
/// This macro saves you from writing boilerplate subscript code. To use it, you must
/// first manually add the `@dynamicMemberLookup` attribute to the enclosing type.
///
/// For example, given these types:
/// ```swift
/// struct InnerData {
///     var value: String
/// }
///
/// @dynamicMemberLookup
/// struct Container {
///     @ProxyMembers var inner: InnerData
/// }
/// ```
///
/// You can now access `inner.value` directly on an instance of `Container`:
/// ```swift
/// var container = Container(inner: .init(value: "Hello"))
/// print(container.value) // Prints "Hello"
/// container.value = "World" // Also works
/// ```
///
/// - Precondition: The enclosing type must be marked with the `@dynamicMemberLookup` attribute.
@attached(peer, names: named(subscript))
public macro ProxyMembers() = #externalMacro(module: "ProxyMembersMacros", type: "ProxyMembersMacro")
