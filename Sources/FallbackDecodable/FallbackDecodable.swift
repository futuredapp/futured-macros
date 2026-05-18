import Foundation

/// Wires an enum to `DefaultableDecodableEnum`. Decoding an unknown raw value
/// falls back to the declared case instead of throwing and burning the entire
/// payload.
///
/// **Required `fallback:` argument** — name the case that catches unknown
/// raws. The macro inspects that case's associated-value arity:
///
/// - **Zero arity** (e.g. `case unknown`): the enum must declare a raw type.
///   ```swift
///   @DefaultableEnum(fallback: .unknown)
///   enum FeedEntityType: String, Codable {
///       case performer, place, promoter, unknown
///   }
///   ```
///
/// - **One arity** (e.g. `case unknown(String)`): no raw type — the macro
///   synthesises `init?(rawValue:)` / `rawValue` using case names as raw
///   strings, and the fallback preserves the original BE value.
///   ```swift
///   @DefaultableEnum(fallback: .unknown)
///   enum FeedEntityType: Codable {
///       case performer, place, promoter
///       case unknown(String)
///   }
///   ```
@attached(member, names: named(fallback), named(init), named(rawValue))
@attached(extension, conformances: DefaultableDecodableEnum)
public macro DefaultableEnum(fallback: Any) = #externalMacro(
    module: "DefaultableEnumMacros",
    type: "DefaultableEnumMacro"
)

/// Global sink for fallback log lines. Default no-op. Apps wire their own
/// logger once at startup (typically in `Container.init`) before any decoding
/// begins; set-after-decode is racy.
public enum DefaultableEnumLogger {
    public static var sink: @Sendable (String) -> Void = { _ in }
}
