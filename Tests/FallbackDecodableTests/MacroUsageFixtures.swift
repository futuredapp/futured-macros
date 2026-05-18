import FallbackDecodable

// Real-macro fixtures — purely a compile-time check that
// `@FallbackDecodable(fallback: SelfEnum.case)` resolves against the same
// enum the attribute is attached to. If this file compiles, the macro
// API is usable from production code.

@FallbackDecodable(fallback: FixtureBranchA.unknown)
enum FixtureBranchA: String, Sendable, Equatable {
    case a, b, unknown
}

@FallbackDecodable(fallback: FixtureIntRaw.unknown)
enum FixtureIntRaw: Int, Sendable, Equatable {
    case zero = 0, one = 1, unknown = -1
}

@FallbackDecodable(fallback: FixtureNonUnknown.horizontal)
enum FixtureNonUnknown: String, Sendable, Equatable {
    case horizontal, vertical
}

@FallbackDecodable(fallback: FixtureBranchB.unknown)
enum FixtureBranchB: Sendable, Equatable {
    case a, b
    case unknown(String)
}
