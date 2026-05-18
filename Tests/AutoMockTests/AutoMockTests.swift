import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(AutoMockMacros)
import AutoMockMacros

let testMacros: [String: Macro.Type] = [
    "AutoMock": AutoMockMacro.self
]
#endif

final class AutoMockTests: XCTestCase {
    func testBasicComponentModelProtocol() throws {
        #if canImport(AutoMockMacros)
        assertMacroExpansion(
            """
            @AutoMock
            protocol HomeComponentModelProtocol: ComponentModel {
                var isReady: Bool { get }
                func onAppear() async
            }
            """,
            expandedSource:
            """
            protocol HomeComponentModelProtocol: ComponentModel {
                var isReady: Bool { get }
                func onAppear() async
            }

            #if DEBUG
            @Observable
            final class HomeComponentModelMock: HomeComponentModelProtocol {
                var onEvent: (Event) -> Void = { _ in
                }

                var isReady: Bool = false

                func onAppear() async {
                }
            }
            #endif
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAllDefaultableTypes() throws {
        #if canImport(AutoMockMacros)
        assertMacroExpansion(
            """
            @AutoMock
            protocol SettingsComponentModelProtocol: ComponentModel {
                var title: String { get }
                var count: Int { get }
                var enabled: Bool { get }
                var subtitle: String? { get }
                var ids: [Int] { get }
                var attributes: [String: String] { get }
            }
            """,
            expandedSource:
            """
            protocol SettingsComponentModelProtocol: ComponentModel {
                var title: String { get }
                var count: Int { get }
                var enabled: Bool { get }
                var subtitle: String? { get }
                var ids: [Int] { get }
                var attributes: [String: String] { get }
            }

            #if DEBUG
            @Observable
            final class SettingsComponentModelMock: SettingsComponentModelProtocol {
                var onEvent: (Event) -> Void = { _ in
                }

                var title: String = ""
                var count: Int = 0
                var enabled: Bool = false
                var subtitle: String? = nil
                var ids: [Int] = []
                var attributes: [String: String] = [:]
            }
            #endif
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testNonDefaultableType() throws {
        #if canImport(AutoMockMacros)
        assertMacroExpansion(
            """
            @AutoMock
            protocol DetailComponentModelProtocol: ComponentModel {
                var projection: SomeProjection { get }
                var isReady: Bool { get }
            }
            """,
            expandedSource:
            """
            protocol DetailComponentModelProtocol: ComponentModel {
                var projection: SomeProjection { get }
                var isReady: Bool { get }
            }

            #if DEBUG
            @Observable
            final class DetailComponentModelMock: DetailComponentModelProtocol {
                var onEvent: (Event) -> Void = { _ in
                }

                var projection: SomeProjection
                var isReady: Bool = false

                init(
                    projection: SomeProjection
                ) {
                    self.projection = projection
                }
            }
            #endif
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testReturningMethods() throws {
        #if canImport(AutoMockMacros)
        assertMacroExpansion(
            """
            @AutoMock
            protocol QueryComponentModelProtocol: ComponentModel {
                func isItemSelected() -> Bool
                func makeTitle() -> String
                func makeProjection() -> SomeProjection
            }
            """,
            expandedSource:
            #"""
            protocol QueryComponentModelProtocol: ComponentModel {
                func isItemSelected() -> Bool
                func makeTitle() -> String
                func makeProjection() -> SomeProjection
            }

            #if DEBUG
            @Observable
            final class QueryComponentModelMock: QueryComponentModelProtocol {
                var onEvent: (Event) -> Void = { _ in
                }

                func isItemSelected() -> Bool {
                    false
                }

                func makeTitle() -> String {
                    ""
                }

                func makeProjection() -> SomeProjection {
                fatalError("\(#function) not stubbed in \(Self.self) — override the mock to use this method")
                }
            }
            #endif
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testTypedThrows() throws {
        #if canImport(AutoMockMacros)
        assertMacroExpansion(
            """
            @AutoMock
            protocol AuthComponentModelProtocol: ComponentModel {
                func login() async throws(AppError)
                func validate() async throws(AppError) -> Bool
            }
            """,
            expandedSource:
            """
            protocol AuthComponentModelProtocol: ComponentModel {
                func login() async throws(AppError)
                func validate() async throws(AppError) -> Bool
            }

            #if DEBUG
            @Observable
            final class AuthComponentModelMock: AuthComponentModelProtocol {
                var onEvent: (Event) -> Void = { _ in
                }

                func login() async throws(AppError) {
                }

                func validate() async throws(AppError) -> Bool {
                    false
                }
            }
            #endif
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testGetSetProperty() throws {
        #if canImport(AutoMockMacros)
        assertMacroExpansion(
            """
            @AutoMock
            protocol FormComponentModelProtocol: ComponentModel {
                var firstName: String { get set }
                var modalItem: SomeItem? { get set }
            }
            """,
            expandedSource:
            """
            protocol FormComponentModelProtocol: ComponentModel {
                var firstName: String { get set }
                var modalItem: SomeItem? { get set }
            }

            #if DEBUG
            @Observable
            final class FormComponentModelMock: FormComponentModelProtocol {
                var onEvent: (Event) -> Void = { _ in
                }

                var firstName: String = ""
                var modalItem: SomeItem? = nil
            }
            #endif
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDiagnosticMustBeProtocol() throws {
        #if canImport(AutoMockMacros)
        assertMacroExpansion(
            """
            @AutoMock
            struct NotAProtocol {
            }
            """,
            expandedSource:
            """
            struct NotAProtocol {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "`@AutoMock` can only be applied to a `protocol`",
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

    func testDiagnosticBadProtocolName() throws {
        #if canImport(AutoMockMacros)
        assertMacroExpansion(
            """
            @AutoMock
            protocol Foo {
            }
            """,
            expandedSource:
            """
            protocol Foo {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "`@AutoMock` requires the protocol name to end in `Protocol` (e.g. `HomeComponentModelProtocol`) so the mock class name can be derived (`HomeComponentModelMock`)",
                    line: 2,
                    column: 10
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
