/// A macro that flattens access to specified properties of the property it's attached to.
///
/// Apply this macro directly to a `var` or `let` property that holds a nested struct.
/// The macro will automatically generate new top-level properties that forward
/// to the properties within the nested struct.
///
/// - Parameters:
///   - properties: A variadic list of property names within the attached property
///                 that should be flattened to the parent type.
///
/// Example:
/// ```swift
/// struct MyContainer {
///     @FlattenProperties("someProperty", "anotherProperty")
///     var myDataProperty: MyNestedData // Macro attached directly here
///
///     // Automatically generates:
///     // var someProperty: SomeType { get { myDataProperty.someProperty } set { myDataProperty.someProperty = newValue } }
///     // var anotherProperty: AnotherType { get { myDataProperty.anotherProperty } set { myDataProperty.anotherProperty = newValue } }
/// }
///
/// struct MyNestedData {
///     var someProperty: SomeType
///     var anotherProperty: AnotherType
/// }
/// ```
@attached(peer, names: arbitrary)
public macro FlattenProperties(_ properties: String...) = #externalMacro(module: "FlattenPropertiesMacros", type: "FlattenPropertiesMacro")
