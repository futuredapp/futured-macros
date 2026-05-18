/// Generates a `#if DEBUG`-wrapped `@Observable final class <Name>Mock` that
/// conforms to the attached protocol with empty stubs and primitive-default
/// property values.
///
/// Apply to a `*ComponentModelProtocol` declaration. The macro:
/// - Strips the trailing `Protocol` from the protocol's name to compute the
///   mock class name (`HomeComponentModelProtocol` → `HomeComponentModelMock`).
/// - Emits `var onEvent: (Event) -> Void = { _ in }` (required by
///   `ComponentModel`).
/// - Emits a stored `var` for each property requirement, with a primitive
///   default when the type is trivially defaultable (`String`, `Int`, `Bool`,
///   `Optional`, `Array`, `Dictionary`, `Set`, numeric).
/// - Properties with non-defaultable types become required `init` parameters.
/// - Methods get empty bodies (or hardcoded primitive returns where the
///   return type allows; `fatalError` for custom return types).
///
/// ```swift
/// @AutoMock
/// protocol HomeComponentModelProtocol: ComponentModel {
///     var projection: HomeCacheProjection { get }
///     var isPushPromptVisible: Bool { get }
///     func onAppear() async
///     func onEventTapped(_ event: EventListItem)
/// }
/// ```
///
/// Expands to (paired with the original protocol):
///
/// ```swift
/// #if DEBUG
/// @Observable
/// final class HomeComponentModelMock: HomeComponentModelProtocol {
///     var onEvent: (Event) -> Void = { _ in }
///     var projection: HomeCacheProjection
///     var isPushPromptVisible: Bool = false
///
///     init(projection: HomeCacheProjection) {
///         self.projection = projection
///     }
///
///     func onAppear() async {}
///     func onEventTapped(_: EventListItem) {}
/// }
/// #endif
/// ```
///
/// Customize the generated mock through three mechanisms — none requires
/// macro arguments:
/// 1. Post-init property mutation at the call site (`mock.x = "Jan"`).
/// 2. Convenience inits in a `#if DEBUG` extension.
/// 3. Skip the macro for protocols whose mock needs meaningful in-method
///    behavior (e.g. `toggleFavorite()` mutating state).
///
/// - Important: The attached protocol's name must end in `Protocol`. The
///   macro emits a `protocolNameMustEndInProtocol` diagnostic otherwise.
@attached(peer, names: arbitrary)
public macro AutoMock() = #externalMacro(module: "AutoMockMacros", type: "AutoMockMacro")
