import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// MARK: - Mock Types for Testing Macro Expansion

// These mock types are crucial because the macro expansion environment needs
// to compile the code that the macro *generates*. Their properties and conformance
// must match what the macro expects and produces.

// Mock for a common nested data structure (e.g., from an API response)
struct MockApiCategoriesResponse: Equatable, Codable {
    var items: [MockCategoryItem]
    static var empty: Self { .init(items: []) }
}

struct MockCategoryItem: Equatable, Codable {
    var id: String
    var type: MockCategoryType
}

enum MockCategoryType: String, Equatable, Codable {
    case general = "general"
    case specific = "specific"
}

// Mock for detailed evaluation of a category
struct MockCategoryEvaluation: Equatable, Codable {
    var score: Int = 0
    static var sample: Self { .init(score: 100) }
}

// Generic ItemState to simulate loading/populated states for nested data
enum ItemState<T: Equatable>: Equatable {
    case loading
    case populated(T)
    case error(String)
}

// Mock for a general data model that might be the target of flattening
struct GenericDataModel: Equatable {
    var responseData: MockApiCategoriesResponse
    var itemDetails: [String: ItemState<MockCategoryEvaluation>]
    var itemIdentifiers: [String] { [] }
    var categoryMap: [String: MockCategoryType] { [:] }
}

// A simple nested struct for more generic `foo`, `bar` tests
struct SimpleNestedData: Equatable {
    var name: String
    var count: Int
    var isActive: Bool { true }
}

// Another generic settings-like struct
struct UserPreferences: Equatable {
    var themeName: String
    var userID: String
    var languageCode: String
}

// State for a UI component
enum UIComponentState: Equatable {
    case initializing
    case ready
    case failed(String)
}

// --- Macro Test Setup ---
// This block defines the macros available for testing.
// It's guarded by `canImport` for platform compatibility reasons.
#if canImport(FlattenPropertiesMacros) // This correctly imports the macro *implementation* module
import FlattenPropertiesMacros

// The dictionary mapping macro names to their implementations
let testMacros: [String: Macro.Type] = [
    "FlattenProperties": FlattenPropertiesMacro.self
]
#endif
// --- End Macro Test Setup ---


// MARK: - FlattenProperties Macro Test Cases

final class FlattenPropertiesTests: XCTestCase {
    // Each test function now explicitly throws, and includes the #if canImport check
    func testFlattenPropertiesMacro_WithStandardDataModel() throws {
#if canImport(FlattenPropertiesMacros)
        assertMacroExpansion(
            """
            struct DataContainer: Equatable {
                var uiState: UIComponentState
                @FlattenProperties("responseData", "itemDetails", "itemIdentifiers", "categoryMap")
                var coreData: GenericDataModel
            
                static func makeEmpty(state: UIComponentState) -> Self {
                    .init(uiState: state, coreData: .init(responseData: .empty, itemDetails: [:]))
                }
            }
            """,
            expandedSource:
            """
            struct DataContainer: Equatable {
                var uiState: UIComponentState
                @FlattenProperties("responseData", "itemDetails", "itemIdentifiers", "categoryMap")
                var coreData: GenericDataModel
            
                var responseData: MockApiCategoriesResponse {
                    get { coreData.responseData }
                    set { coreData.responseData = newValue }
                }
                var itemDetails: [String: ItemState<MockCategoryEvaluation>] {
                    get { coreData.itemDetails }
                    set { coreData.itemDetails = newValue }
                }
                var itemIdentifiers: [String] {
                    get { coreData.itemIdentifiers }
                }
                var categoryMap: [String: MockCategoryType] {
                    get { coreData.categoryMap }
                }
                static func makeEmpty(state: UIComponentState) -> Self {
                    .init(uiState: state, coreData: .init(responseData: .empty, itemDetails: [:]))
                }
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testFlattenPropertiesMacro_WithSimpleNestedData() throws {
#if canImport(FlattenPropertiesMacros)
        assertMacroExpansion(
            """
            struct ViewModel: Equatable {
                var viewState: UIComponentState
                @FlattenProperties("name", "count", "isActive")
                var currentItem: SimpleNestedData
            
                static func initial(state: UIComponentState) -> Self {
                    .init(viewState: state, currentItem: .init(name: "Default", count: 0))
                }
            }
            """,
            expandedSource:
            """
            struct ViewModel: Equatable {
                var viewState: UIComponentState
                @FlattenProperties("name", "count", "isActive")
                var currentItem: SimpleNestedData
            
                var name {
                    get { currentItem.name }
                    set { currentItem.name = newValue }
                }
                var count {
                    get { currentItem.count }
                    set { currentItem.count = newValue }
                }
                var isActive {
                    get { currentItem.isActive }
                }
                static func initial(state: UIComponentState) -> Self {
                    .init(viewState: state, currentItem: .init(name: "Default", count: 0))
                }
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testFlattenPropertiesMacro_WithAppSettings() throws {
#if canImport(FlattenPropertiesMacros)
        assertMacroExpansion(
            """
            struct SettingsController: Equatable {
                var status: UIComponentState
                @FlattenProperties("themeName", "userID", "languageCode")
                var userPrefs: UserPreferences
            
                static func defaultConfig() -> Self {
                    .init(status: .ready, userPrefs: .init(themeName: "light", userID: "guest", languageCode: "en"))
                }
            }
            """,
            expandedSource:
            """
            struct SettingsController: Equatable {
                var status: UIComponentState
                @FlattenProperties("themeName", "userID", "languageCode")
                var userPrefs: UserPreferences
            
                var themeName {
                    get { userPrefs.themeName }
                    set { userPrefs.themeName = newValue }
                }
                var userID {
                    get { userPrefs.userID }
                    set { userPrefs.userID = newValue }
                }
                var languageCode {
                    get { userPrefs.languageCode }
                    set { userPrefs.languageCode = newValue }
                }
                static func defaultConfig() -> Self {
                    .init(status: .ready, userPrefs: .init(themeName: "light", userID: "guest", languageCode: "en"))
                }
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testFlattenPropertiesMacro_NotAPropertyDeclaration() throws {
#if canImport(FlattenPropertiesMacros)
        assertMacroExpansion(
            """
            struct ContainsFunction {
                @FlattenProperties("someProp")
                static func utilityFunction() {}
            }
            """,
            expandedSource:
            """
            struct ContainsFunction {
                static func utilityFunction() {}
            }
            """,
            diagnostics: [
                .init(message: "FlattenProperties can only be applied to a 'var' or 'let' property declaration.", line: 3, column: 5)
            ],
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testFlattenPropertiesMacro_NoArguments() throws {
#if canImport(FlattenPropertiesMacros)
        assertMacroExpansion(
            """
            struct MissingArgsContainer {
                @FlattenProperties
                var data: GenericDataModel
                func setup() {}
            }
            """,
            expandedSource:
            """
            struct MissingArgsContainer {
                var data: GenericDataModel
                func setup() {}
            }
            """,
            diagnostics: [
                .init(message: "FlattenProperties macro requires at least one property name argument.", line: 3, column: 5)
            ],
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testFlattenPropertiesMacro_NonStringArguments() throws {
#if canImport(FlattenPropertiesMacros)
        assertMacroExpansion(
            """
            struct InvalidArgsContainer {
                @FlattenProperties(123, true)
                var data: GenericDataModel
                func setup() {}
            }
            """,
            expandedSource:
            """
            struct InvalidArgsContainer {
                var data: GenericDataModel
                func setup() {}
            }
            """,
            diagnostics: [
                .init(message: "Arguments to @FlattenProperties must be string literals.", line: 3, column: 22),
                .init(message: "Arguments to @FlattenProperties must be string literals.", line: 3, column: 27),
            ],
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
