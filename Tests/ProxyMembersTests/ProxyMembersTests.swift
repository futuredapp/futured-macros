import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(ProxyMembersMacros)
import ProxyMembersMacros

let testMacros: [String: Macro.Type] = [
    "ProxyMembers": ProxyMembersMacro.self,
]
#endif

final class ProxyMembersTests: XCTestCase {

    // MARK: - Success Cases
    func testProxyMembersOnVarProperty() throws {
        #if canImport(ProxyMembersMacros)
        assertMacroExpansion(
            """
            struct InnerData {
                var mutableValue: String
            }
            
            @dynamicMemberLookup
            struct Container {
                @ProxyMembers var inner: InnerData
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

    func testProxyMembersOnLetProperty() throws {
        #if canImport(ProxyMembersMacros)
        assertMacroExpansion(
            """
            struct InnerData {
                let immutableValue: Int
            }
            @dynamicMemberLookup
            struct Container {
                @ProxyMembers let inner: InnerData
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

    func testProxyMembersWithGenericTypes() throws {
        #if canImport(ProxyMembersMacros)
        assertMacroExpansion(
            """
            struct InnerGeneric<T> {
                var value: T
            }
            @dynamicMemberLookup
            struct OuterGeneric<T> {
                @ProxyMembers var inner: InnerGeneric<T>
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

    func testProxyMembersMultipleProperties() throws {
        #if canImport(ProxyMembersMacros)
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
                @ProxyMembers let innerA: InnerDataA
                @ProxyMembers let innerB: InnerDataB
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
}
