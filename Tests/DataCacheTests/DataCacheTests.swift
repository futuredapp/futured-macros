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
    "ProxySetter": ProxySetterMacro.self
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

                struct _Versions: Hashable {
                    var userName: UInt = 0
                    var revision: UInt = 0
                }
            
                private var _version: _Versions = .init()

                private var _subscribtions: [SubscriptionBox<Global>] = []
            
                func makeSubscriber(predicate: @escaping (_ oldValue: _Versions, _ newValue: _Versions) -> Bool) -> AsyncStream<Global> {
                    let subscriptionBox = SubscriptionBox<Global>(initialVersion: _version, predicate: predicate)
                    let stream = AsyncStream<Global> { continuation in
                        continuation.onTermination = { [weak self] _ in
                            self?._subscribtions.removeAll {
                                $0 === subscriptionBox
                            }
                        }
                        subscriptionBox.yeald = {
                            continuation.yield($0)
                        }
                    }
                    self._subscribtions.append(subscriptionBox)
                    return stream
                }
            
                func applyChanges(during block: () -> Void) {
                    block()
                    for subscribtion in _subscribtions {
                        if subscribtion.responds(to: _version) {
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
                    $0.userName != $1.userName || $0.revision != $1.revision
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
                    @storageRestrictions(initializes: _userName)
                    init(newValue)  {
                        self._userName = newValue
                    }
                    get {
                        self._userName
                    }
                    set {
                        if newValue != self._userName {
                            self._version.userName = self._version.userName &+ 1
                        }
                        self._userName = newValue
                    }
                }

                private var _userName: String?
                var revision: Int = 0 {
                    @storageRestrictions(initializes: _revision)
                    init(newValue)  {
                        self._revision = newValue
                    }
                    get {
                        self._revision
                    }
                    set {
                        if newValue != self._revision {
                            self._version.revision = self._version.revision &+ 1
                        }
                        self._revision = newValue
                    }
                }

                private var _revision: Int = 0

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

    func testProxyExpansion() throws {
#if canImport(DataCacheMacros)
        assertMacroExpansion(
            """
            @ProxySetter
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
            final class Global {
                var userName: String?
                var revision: Int = 0
            
                init(userName: String?) {
                    self.userName = userName
                }
            }
            
            extension Global: ProxySettable {
                final class Proxy: ProxyObject<Global> {
                    private var ref: Global
            
                    init(ref: Global) {
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
            }
            """#
            ,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

}
