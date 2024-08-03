/// A macro that produces code form a given enum to be Identifiable even if it has associated values.
/// Macro generates a new nested enum CaseID that is Identifiable and Hashable.
/// CaseID has all cases of the original enum, but ignores associated values which not contains an "id" string in the parameter name.
/// The cases with associated values that contains "id" string in the parameter name are used to generate the rawValue of the CaseID.
@attached(member, names: arbitrary)
public macro EnumIdentable() = #externalMacro(module: "EnumIdentableMacros",type: "EnumIdentableMacro")
