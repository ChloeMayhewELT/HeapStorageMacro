import MacroTesting
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(HeapStorageMacroMacros)
import HeapStorageMacroMacros

let testMacros: [String: Macro.Type] = [
    "heapStorage": HeapStorage.self,
]
#endif

final class HeapStorageMacroTests: XCTestCase {

    func testHeapStorage() throws {
        #if canImport(HeapStorageMacroMacros)
        assertMacro(["HeapStorage": HeapStorage.self]) {
            """
            @HeapStorage var myValue: Int
            """
        } expansion: {
            """
            var myValue: Int {
                @storageRestrictions(initializes: _myValue)
                init(initialValue) {
                    _myValue = .init(wrappedValue: initialValue)
                }
                get {
                    _myValue.wrappedValue
                }
                set {
                    _myValue.wrappedValue = newValue
                }
            }

            private var _myValue: StoredOnHeap<Int>
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }


    func testHeapStorageWithInitialValue() throws {
        #if canImport(HeapStorageMacroMacros)
        assertMacro(["HeapStorage": HeapStorage.self]) {
            """
            @HeapStorage var myValue: Int = 267
            """
        } expansion: {
            """
            var myValue: Int = 267 {
                get {
                    _myValue.wrappedValue
                }
                set {
                    _myValue.wrappedValue = newValue
                }
            }

            private var _myValue: StoredOnHeap<Int> = .init(wrappedValue: 267)
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
