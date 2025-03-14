import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(InitMacroImplementation)
import InitMacroImplementation

let testMacros: [String: Macro.Type] = [
	"Init": InitMacro.self,
]
final class swift_macro_public_initTests: XCTestCase {
	func test__init__simpleStruct_defaultAccess__initIsInternal_allFieldsIncluded() async throws {
		assertMacroExpansion("""
		@Init()
		struct Foo {
			var a: String
			var b: Int
		}
		""",
		expandedSource: """
		struct Foo {
			var a: String
			var b: Int
		}

		extension Foo {
			init(a: String, b: Int) {
				self.a = a
				self.b = b
			}
		}
		""", macros: testMacros)
	}
}
#else
final class swift_macro_public_initTests: XCTestCase {
	func testMacro() throws {
		throw XCTSkip("macros are only supported when running tests for the host platform")
	}
}
#endif
