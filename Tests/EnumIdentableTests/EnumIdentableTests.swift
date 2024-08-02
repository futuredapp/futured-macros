import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(EnumIdentableMacros)
import EnumIdentableMacros

let testMacros: [String: Macro.Type] = [
    "EnumIdentable": EnumIdentableMacro.self
]
#endif

final class EnumIdentableTests: XCTestCase {
    func testMacro() throws {
        #if canImport(EnumIdentableMacros)
        assertMacroExpansion(
            """
            @EnumIdentable
            enum TestEnum {
                case one
                case two
                case three
            }
            """
            ,
            expandedSource:
            """
            enum TestEnum {
                case one
                case two
                case three

                enum CaseID: String {
                    case one
                    case two
                    case three
                }

                var caseId: CaseID {
                    switch self {
                    case .one:
                        .one
                    case .two:
                        .two
                    case .three:
                        .three
                    }
                }

                var id: String {
                    self.caseId.rawValue
                }

                func hash(into hasher: inout Hasher) {
                    hasher.combine(id)
                }

                static func == (lhs: Self, rhs: Self) -> Bool {
                    lhs.id == rhs.id
                }
            }
            """
            ,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacro2() throws {
        #if canImport(EnumIdentableMacros)
        assertMacroExpansion(
            """
            @EnumIdentable
            enum TestEnum {
                case one(String)
            }
            """
            ,
            expandedSource:
            """
            enum TestEnum {
                case one(String)

                enum CaseID: String {
                    case one
                }

                var caseId: CaseID {
                    switch self {
                    case .one:
                        .one
                    }
                }

                var id: String {
                    self.caseId.rawValue
                }

                func hash(into hasher: inout Hasher) {
                    hasher.combine(id)
                }

                static func == (lhs: Self, rhs: Self) -> Bool {
                    lhs.id == rhs.id
                }
            }
            """
            ,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacro3() throws {
        #if canImport(EnumIdentableMacros)
        assertMacroExpansion(
            """
            @EnumIdentable
            enum TestEnum {
                case one, two, three
            }
            """
            ,
            expandedSource:
            """
            enum TestEnum {
                case one, two, three

                enum CaseID: String {
                    case one
                    case two
                    case three
                }

                var caseId: CaseID {
                    switch self {
                    case .one:
                        .one
                    case .two:
                        .two
                    case .three:
                        .three
                    }
                }

                var id: String {
                    self.caseId.rawValue
                }

                func hash(into hasher: inout Hasher) {
                    hasher.combine(id)
                }

                static func == (lhs: Self, rhs: Self) -> Bool {
                    lhs.id == rhs.id
                }
            }
            """
            ,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacro4() throws {
        #if canImport(EnumIdentableMacros)
        assertMacroExpansion(
            """
            @EnumIdentable
            enum TestEnum {
                case one(id: String)
                case two(model: String)
                case three
                case four(xxx: Int, modelId: String)
            }
            """
            ,
            expandedSource:
            """
            enum TestEnum {
                case one(id: String)
                case two(model: String)
                case three
                case four(xxx: Int, modelId: String)

                enum CaseID {
                    case one(id: String)
                    case two
                    case three
                    case four(modelId: String)
                    var rawValue: String {
                        switch self {
                        case let .one(id):
                            "one-\\(id)"
                        case .two:
                            "two"
                        case .three:
                            "three"
                        case let .four(modelId):
                            "four-\\(modelId)"
                        }
                    }
                }

                var caseId: CaseID {
                    switch self {
                    case let .one(id):
                        .one(id: id)
                    case .two:
                        .two
                    case .three:
                        .three
                    case let .four(_, modelId):
                        .four(modelId: modelId)
                    }
                }

                var id: String {
                    self.caseId.rawValue
                }

                func hash(into hasher: inout Hasher) {
                    hasher.combine(id)
                }

                static func == (lhs: Self, rhs: Self) -> Bool {
                    lhs.id == rhs.id
                }
            }
            """
            ,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
