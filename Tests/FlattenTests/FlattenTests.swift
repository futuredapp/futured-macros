import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(FlattenMacros)
import FlattenMacros

let testMacros: [String: Macro.Type] = [
    "Flatten": FlattenMacro.self,
]
#endif

final class FlattenTests: XCTestCase {

    // MARK: - Success Cases
    func testFlattenOnVarProperty() throws {
        #if canImport(FlattenMacros)
        assertMacroExpansion(
            """
            struct InnerData {
                var mutableValue: String
            }
            
            @dynamicMemberLookup
            struct Container {
                @Flatten var inner: InnerData
            }
            """,
            expandedSource:
            #"""
            struct InnerData {
                var mutableValue: String
            }
            
            @dynamicMemberLookup
            struct Container {
                var inner: InnerData
            
                subscript <Value>(dynamicMember keyPath: KeyPath<InnerData, Value>) -> Value {
                    inner[keyPath: keyPath]
                }
            
                subscript <Value>(dynamicMember keyPath: WritableKeyPath<InnerData, Value>) -> Value {
                    get {
                        inner[keyPath: keyPath]
                    }
                    set {
                        inner[keyPath: keyPath] = newValue
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testFlattenOnLetProperty() throws {
        #if canImport(FlattenMacros)
        assertMacroExpansion(
            """
            struct InnerData {
                let immutableValue: Int
            }
            @dynamicMemberLookup
            struct Container {
                @Flatten let inner: InnerData
            }
            """,
            expandedSource:
            #"""
            struct InnerData {
                let immutableValue: Int
            }
            @dynamicMemberLookup
            struct Container {
                let inner: InnerData
            
                subscript <Value>(dynamicMember keyPath: KeyPath<InnerData, Value>) -> Value {
                    inner[keyPath: keyPath]
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testFlattenWithGenericTypes() throws {
        #if canImport(FlattenMacros)
        assertMacroExpansion(
            """
            struct InnerGeneric<T> {
                var value: T
            }
            @dynamicMemberLookup
            struct OuterGeneric<T> {
                @Flatten var inner: InnerGeneric<T>
            }
            """,
            expandedSource:
            #"""
            struct InnerGeneric<T> {
                var value: T
            }
            @dynamicMemberLookup
            struct OuterGeneric<T> {
                var inner: InnerGeneric<T>
            
                subscript <Value>(dynamicMember keyPath: KeyPath<InnerGeneric<T>, Value>) -> Value {
                    inner[keyPath: keyPath]
                }
            
                subscript <Value>(dynamicMember keyPath: WritableKeyPath<InnerGeneric<T>, Value>) -> Value {
                    get {
                        inner[keyPath: keyPath]
                    }
                    set {
                        inner[keyPath: keyPath] = newValue
                    }
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testFlattenMultipleProperties() throws {
        #if canImport(FlattenMacros)
        assertMacroExpansion(
            """
            struct InnerDataA {
                let valueA: Int
            }
            struct InnerDataB {
                let valueB: String
            }
            @dynamicMemberLookup
            struct Container {
                @Flatten let innerA: InnerDataA
                @Flatten let innerB: InnerDataB
            }
            """,
            expandedSource:
            #"""
            struct InnerDataA {
                let valueA: Int
            }
            struct InnerDataB {
                let valueB: String
            }
            @dynamicMemberLookup
            struct Container {
                let innerA: InnerDataA
            
                subscript <Value>(dynamicMember keyPath: KeyPath<InnerDataA, Value>) -> Value {
                    innerA[keyPath: keyPath]
                }
                let innerB: InnerDataB

                subscript <Value>(dynamicMember keyPath: KeyPath<InnerDataB, Value>) -> Value {
                    innerB[keyPath: keyPath]
                }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Failure & Diagnostic Cases

    func testFlattenEmitsErrorForMissingTypeAnnotation() throws {
        #if canImport(FlattenMacros)
        assertMacroExpansion(
            """
            @dynamicMemberLookup
            struct Container {
                @Flatten var inner
            }
            """,
            expandedSource:
            """
            @dynamicMemberLookup
            struct Container {
                var inner
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "The property with @Flatten must have an explicit type annotation.", line: 3, column: 17)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testFlattenEmitsErrorWhenNotOnProperty() throws {
        #if canImport(FlattenMacros)
        assertMacroExpansion(
            """
            struct Container {
                @Flatten func myFunc() {}
            }
            """,
            expandedSource:
            """
            struct Container {
                func myFunc() {}
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Flatten can only be attached to a property declaration.", line: 2, column: 5)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
