import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(DataCacheMacros)
import DataCacheMacros

let testMacros: [String: Macro.Type] = [
    "DataCache": DataCacheMacro.self,
    "CacheSubscribe": CacheSubscriptionMacro.self,
]
let versionedPropertyMacros: [String: Macro.Type] = [
    "VersionedProperty": VersionedPropertyMacro.self,
]
#endif

final class DataCacheTests: XCTestCase {
    func testClassExpansion() throws {
#if canImport(DataCacheMacros)
        assertMacroExpansion(
            """
            @MainActor
            @DataCache
            final class Global {
                var userName: String?
                var revision: Int = 0
            
                init(userName: String?) {
                    self.userName = userName
                }
            }
            """
            ,
            expandedSource:
            #"""
            @MainActor
            final class Global {
                @VersionedProperty
                var userName: String?
                @VersionedProperty
                var revision: Int = 0
            
                init(userName: String?) {
                    self.userName = userName
                }
            
                struct __Versions {
                    var userName: UInt = 0
                    var revision: UInt = 0
                }
            
                private var __version: __Versions = .init()
            
                private final class SubscriptionBox {
                    internal init(
                        initialVersion: __Versions,
                        predicate: @escaping (_ oldValue: __Versions, _ newValue: __Versions) -> Bool
                    ) {
                        self.initialVersion = initialVersion
                        self.predicate = predicate
                    }
            
                    private var initialVersion: __Versions
                    private var predicate: (_ oldValue: __Versions, _ newValue: __Versions) -> Bool
            
                    // calling convention
                    var yeald: ((Global) -> Void)!
            
                    func responds(to newVersion: __Versions) -> Bool {
                        defer {
                            initialVersion = newVersion
                        }
                        return predicate(initialVersion, newVersion)
                    }
                }
            
                private var subscribtions: [SubscriptionBox] = []
            
                func makeSubscriber(predicate: @escaping (_ oldValue: __Versions, _ newValue: __Versions) -> Bool) -> AsyncStream<Global> {
                    let subscriptionBox = SubscriptionBox(initialVersion: __version, predicate: predicate)
                    let stream = AsyncStream<Global> { continuation in
                        continuation.onTermination = { [weak self] _ in
                            self?.subscribtions.removeAll {
                                $0 === subscriptionBox
                            }
                        }
                        subscriptionBox.yeald = {
                            continuation.yield($0)
                        }
                    }
                    self.subscribtions.append(subscriptionBox)
                    return stream
                }
            
                final class ProxySetter {
                    private var ref: Global
            
                    internal init(ref: Global) {
                        self.ref = ref
                    }
            
                    var userName: String? {
                        get {
                            ref.userName
                        }
                        set {
                            ref.userName = newValue
                        }
                    }
            
                    var revision: Int  {
                        get {
                            ref.revision
                        }
                        set {
                            ref.revision = newValue
                        }
                    }
                }
            
                func transaction(eval: (ProxySetter) -> Void) {
                    eval(ProxySetter(ref: self))
                    evaluateSubscribtions()
                }
            
                private func evaluateSubscribtions() {
                    for subscribtion in subscribtions {
                        if subscribtion.responds(to: __version) {
                            subscribtion.yeald(self)
                        }
                    }
                }
            }
            
            extension Global: VersionedDataCache {
            }
            """#
            ,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testSubscriberExpansion() throws {
#if canImport(DataCacheMacros)
        assertMacroExpansion(
            #"""
            #CacheSubscribe(on: global, properties: \.userName, \.revision)
            """#
            ,
            expandedSource:
            #"""
            global.makeSubscriber(
                predicate: {
                    $0.userName == $1.userName || $0.revision == $1.revision
                }
            )
            """#
            ,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }


    func testVersionedProperty() throws {
#if canImport(DataCacheMacros)
        assertMacroExpansion(
            #"""
            final class Global {
                @VersionedProperty var userName: String?
                @VersionedProperty var revision: Int = 0
            
                init(userName: String?) {
                    self.userName = userName
                }
            }
            """#
            ,
            expandedSource:
            #"""
            final class Global {
                var userName: String? {
                    didSet {
                        if oldValue != self.userName {
                            self.__version.userName = self.__version.userName &+ 1
                        }
                    }
                }
                var revision: Int = 0 {
                    didSet {
                        if oldValue != self.revision {
                            self.__version.revision = self.__version.revision &+ 1
                        }
                    }
                }
            
                init(userName: String?) {
                    self.userName = userName
                }
            }
            """#
            ,
            macros: versionedPropertyMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
