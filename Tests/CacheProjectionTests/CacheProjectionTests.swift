import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(CacheProjectionMacros)
import CacheProjectionMacros

let testMacros: [String: Macro.Type] = [
    "CacheProjection": CacheProjectionMacro.self
]
#endif

final class CacheProjectionTests: XCTestCase {
    func testComponentStateExpansion() throws {
        #if canImport(CacheProjectionMacros)
        assertMacroExpansion(
            """
            @CacheProjection(state: ComponentState.self, data: HomeData.self)
            @dynamicMemberLookup
            nonisolated struct HomeCacheProjection {
                static func data(from cache: DataCacheModel) -> Self? {
                    nil
                }
            }
            """,
            expandedSource:
            """
            @dynamicMemberLookup
            nonisolated struct HomeCacheProjection {
                static func data(from cache: DataCacheModel) -> Self? {
                    nil
                }

                var state: ComponentState

                @ProxyMembers var data: HomeData

                static func empty(state: ComponentState) -> Self {
                    Self(state: state, data: .mock)
                }
            }

            extension HomeCacheProjection: CacheProjection {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testProjectionStateExpansion() throws {
        #if canImport(CacheProjectionMacros)
        assertMacroExpansion(
            """
            @CacheProjection(state: ProjectionState.self, data: CurrentBuildingData.self)
            @dynamicMemberLookup
            struct CurrentBuildingCacheProjection {
                static func data(from cache: DataCacheModel) -> Self? {
                    nil
                }
            }
            """,
            expandedSource:
            """
            @dynamicMemberLookup
            struct CurrentBuildingCacheProjection {
                static func data(from cache: DataCacheModel) -> Self? {
                    nil
                }

                var state: ProjectionState

                @ProxyMembers var data: CurrentBuildingData

                static func empty(state: ProjectionState) -> Self {
                    Self(state: state, data: .mock)
                }
            }

            extension CurrentBuildingCacheProjection: CacheProjection {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testKeyedProjection() throws {
        #if canImport(CacheProjectionMacros)
        assertMacroExpansion(
            """
            @CacheProjection(state: ComponentState.self, data: PerformerDetailData.self)
            @dynamicMemberLookup
            nonisolated struct PerformerDetailCacheProjection {
                typealias ID = Int

                static func data(from _: DataCacheModel) -> Self? {
                    nil
                }

                static func data(for id: Int, from cache: DataCacheModel) -> Self? {
                    nil
                }
            }
            """,
            expandedSource:
            """
            @dynamicMemberLookup
            nonisolated struct PerformerDetailCacheProjection {
                typealias ID = Int

                static func data(from _: DataCacheModel) -> Self? {
                    nil
                }

                static func data(for id: Int, from cache: DataCacheModel) -> Self? {
                    nil
                }

                var state: ComponentState

                @ProxyMembers var data: PerformerDetailData

                static func empty(state: ComponentState) -> Self {
                    Self(state: state, data: .mock)
                }
            }

            extension PerformerDetailCacheProjection: CacheProjection {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDiagnosticMustBeStruct() throws {
        #if canImport(CacheProjectionMacros)
        assertMacroExpansion(
            """
            @CacheProjection(state: ComponentState.self, data: BadData.self)
            enum NotAStruct {
                case foo
            }
            """,
            expandedSource:
            """
            enum NotAStruct {
                case foo
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "`@CacheProjection` can only be applied to a `struct`",
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

    func testDiagnosticArgumentNotMetatype() throws {
        #if canImport(CacheProjectionMacros)
        assertMacroExpansion(
            """
            @CacheProjection(state: "string", data: HomeData.self)
            @dynamicMemberLookup
            struct BadProjection {
            }
            """,
            expandedSource:
            """
            @dynamicMemberLookup
            struct BadProjection {
            }

            extension BadProjection: CacheProjection {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "`@CacheProjection` requires metatype arguments (e.g. `state: ComponentState.self`, `data: HomeData.self`)",
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
}
