import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(FallbackDecodableMacros)
import FallbackDecodableMacros

let testMacros: [String: Macro.Type] = [
    "FallbackDecodable": FallbackDecodableMacro.self
]
#endif

final class FallbackDecodableTests: XCTestCase {
    // MARK: - Branch A — explicit raw type, zero-arity fallback

    func testBranchA_unknownFallback() throws {
        #if canImport(FallbackDecodableMacros)
        assertMacroExpansion(
            """
            @FallbackDecodable(fallback: FeedEntityType.unknown)
            enum FeedEntityType: String {
                case performer, place, promoter, unknown
            }
            """,
            expandedSource:
            """
            enum FeedEntityType: String {
                case performer, place, promoter, unknown

                nonisolated static func fallback(for _: String) -> Self {
                    .unknown
                }
            }

            extension FeedEntityType: FallbackDecodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testBranchA_nonUnknownFallback() throws {
        #if canImport(FallbackDecodableMacros)
        assertMacroExpansion(
            """
            @FallbackDecodable(fallback: EventSectionMode.horizontal)
            enum EventSectionMode: String {
                case horizontal, vertical
            }
            """,
            expandedSource:
            """
            enum EventSectionMode: String {
                case horizontal, vertical

                nonisolated static func fallback(for _: String) -> Self {
                    .horizontal
                }
            }

            extension EventSectionMode: FallbackDecodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testBranchA_intRawType() throws {
        #if canImport(FallbackDecodableMacros)
        assertMacroExpansion(
            """
            @FallbackDecodable(fallback: Status.unknown)
            enum Status: Int {
                case ok = 0, warning = 1, unknown = -1
            }
            """,
            expandedSource:
            """
            enum Status: Int {
                case ok = 0, warning = 1, unknown = -1

                nonisolated static func fallback(for _: Int) -> Self {
                    .unknown
                }
            }

            extension Status: FallbackDecodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Branch B — associated-value fallback, no explicit raw type

    func testBranchB_associatedValueUnknown() throws {
        #if canImport(FallbackDecodableMacros)
        assertMacroExpansion(
            """
            @FallbackDecodable(fallback: FeedEntityType.unknown)
            enum FeedEntityType {
                case performer, place, promoter
                case unknown(String)
            }
            """,
            expandedSource:
            #"""
            enum FeedEntityType {
                case performer, place, promoter
                case unknown(String)

                nonisolated init?(rawValue: String) {
                    switch rawValue {
                        case "performer":
                        self = .performer
                        case "place":
                        self = .place
                        case "promoter":
                        self = .promoter
                    default:
                        return nil
                    }
                }

                nonisolated var rawValue: String {
                    switch self {
                        case .performer:
                        return "performer"
                        case .place:
                        return "place"
                        case .promoter:
                        return "promoter"
                    case let .unknown(raw):
                        return raw
                    }
                }

                nonisolated static func fallback(for raw: String) -> Self {
                    .unknown(raw)
                }
            }

            extension FeedEntityType: FallbackDecodable {
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Diagnostics

    func testDiagnostic_mustBeEnum() throws {
        #if canImport(FallbackDecodableMacros)
        assertMacroExpansion(
            """
            @FallbackDecodable(fallback: NotAnEnum.foo)
            struct NotAnEnum {}
            """,
            expandedSource:
            """
            struct NotAnEnum {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "`@FallbackDecodable` can only be applied to an `enum`", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDiagnostic_unknownFallbackCase() throws {
        #if canImport(FallbackDecodableMacros)
        assertMacroExpansion(
            """
            @FallbackDecodable(fallback: E.nope)
            enum E: String {
                case a, b
            }
            """,
            expandedSource:
            """
            enum E: String {
                case a, b
            }

            extension E: FallbackDecodable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Case `.nope` does not exist on this enum. Available cases: .a, .b",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Runtime tests — exercise the shipped protocol directly

    func testRuntime_decodesKnownValue() throws {
        let json = #""performer""#.data(using: .utf8)!
        let value = try JSONDecoder().decode(SimpleTestEnum.self, from: json)
        XCTAssertEqual(value, .performer)
    }

    func testRuntime_decodesUnknownAsBranchAFallback() throws {
        let json = #""garbage""#.data(using: .utf8)!
        let value = try JSONDecoder().decode(SimpleTestEnum.self, from: json)
        XCTAssertEqual(value, .unknown)
    }

    func testRuntime_decodesUnknownAsBranchBPreservesRaw() throws {
        let json = #""venue""#.data(using: .utf8)!
        let value = try JSONDecoder().decode(RichTestEnum.self, from: json)
        XCTAssertEqual(value, .unknown("venue"))

        let roundTrip = try JSONEncoder().encode(value)
        XCTAssertEqual(String(data: roundTrip, encoding: .utf8), #""venue""#)
    }
}

// MARK: - Fixtures (hand-rolled to mirror what the macro generates;
// the macro itself is exercised by the expansion tests above)

import FallbackDecodable

// Branch A — explicit raw type + zero-arity fallback
enum SimpleTestEnum: String, FallbackDecodable {
    case performer, place, promoter, unknown
    nonisolated static func fallback(for _: String) -> Self { .unknown }
}

// Branch B — no explicit raw type + associated-value fallback
enum RichTestEnum: Codable, Equatable, FallbackDecodable {
    case performer, place, promoter
    case unknown(String)

    nonisolated init?(rawValue: String) {
        switch rawValue {
        case "performer": self = .performer
        case "place": self = .place
        case "promoter": self = .promoter
        default: return nil
        }
    }

    nonisolated var rawValue: String {
        switch self {
        case .performer: return "performer"
        case .place: return "place"
        case .promoter: return "promoter"
        case let .unknown(raw): return raw
        }
    }

    nonisolated static func fallback(for raw: String) -> Self { .unknown(raw) }
}
