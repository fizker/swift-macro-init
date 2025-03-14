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
	func test__init__struct_simple_defaultAccess__initIsInternal_allFieldsIncluded() async throws {
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

			init(a: String, b: Int) {
				self.a = a
				self.b = b
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__struct_moreMemberTypes_defaultAccess__initIsInternal_onlyVarsAreIncluded() async throws {
		assertMacroExpansion("""
		@Init()
		struct Foo {
			var a: String
			var b: Int

			func c() -> D { .d }

			enum D {
				case d
			}
		}
		""", expandedSource: """
		struct Foo {
			var a: String
			var b: Int

			func c() -> D { .d }

			enum D {
				case d
			}

			init(a: String, b: Int) {
				self.a = a
				self.b = b
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__struct_membersHasDefaultValues__initParametersHaveSameDefaultValue() async throws {
		assertMacroExpansion("""
		@Init()
		struct Foo {
			var a: String = ""
			var b: Int = 1
		}
		""",
		expandedSource: """
		struct Foo {
			var a: String = ""
			var b: Int = 1

			init(a: String = "", b: Int = 1) {
				self.a = a
				self.b = b
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}
}
#else
final class swift_macro_public_initTests: XCTestCase {
	func testMacro() throws {
		throw XCTSkip("macros are only supported when running tests for the host platform")
	}
}
#endif
