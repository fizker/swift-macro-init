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
final class InitMacroTests: XCTestCase {
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

	func test__init__struct_computedValue__computedValueIsNotIncludedInInit() async throws {
		assertMacroExpansion("""
		@Init()
		struct Foo {
			var a: String
			var b: Int { 1 }
		}
		""",
		expandedSource: """
		struct Foo {
			var a: String
			var b: Int { 1 }

			init(a: String) {
				self.a = a
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

	func test__init__struct_letHasDefaultValue__initIsSkippingMember() async throws {
		assertMacroExpansion("""
		@Init()
		struct Foo {
			let a: String = ""
			var b: Int = 1
		}
		""",
		expandedSource: """
		struct Foo {
			let a: String = ""
			var b: Int = 1

			init(b: Int = 1) {
				self.b = b
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__struct_memberHasImplicitType__initParameterCorrectlyIncludesMember() async throws {
		assertMacroExpansion("""
		@Init()
		struct Foo {
			var a = ""
			var b = 1
			var c = false
			var d = 2.3
		}
		""",
		expandedSource: """
		struct Foo {
			var a = ""
			var b = 1
			var c = false
			var d = 2.3

			init(a: String = "", b: Int = 1, c: Bool = false, d: Double = 2.3) {
				self.a = a
				self.b = b
				self.c = c
				self.d = d
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__struct_publicAccess__initIsPublic() async throws {
		assertMacroExpansion("""
		@Init()
		public struct Foo {
			var a: String
			var b: Int
		}
		""",
		expandedSource: """
		public struct Foo {
			var a: String
			var b: Int

			public init(a: String, b: Int) {
				self.a = a
				self.b = b
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__struct_specificInitAccessLevel__initHasRequestedAccessLevel() async throws {
		assertMacroExpansion("""
		@Init(access: .package)
		public struct Foo {
			var a: String
			var b: Int
		}
		""",
		expandedSource: """
		public struct Foo {
			var a: String
			var b: Int

			package init(a: String, b: Int) {
				self.a = a
				self.b = b
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__class_openAccess__initIsPublic() async throws {
		assertMacroExpansion("""
		@Init()
		open class Foo {
			var a: String
			var b: Int
		}
		""",
		expandedSource: """
		open class Foo {
			var a: String
			var b: Int

			public init(a: String, b: Int) {
				self.a = a
				self.b = b
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__optional__initHasDefaultValueAsNil() async throws {
		assertMacroExpansion("""
		@Init
		class Foo {
			var a: Int?
			var a2: Int? = 1
			var b: String?
			var b2: String? = "foo"
		}
		""",
		expandedSource: """
		class Foo {
			var a: Int?
			var a2: Int? = 1
			var b: String?
			var b2: String? = "foo"

			init(a: Int? = nil, a2: Int? = 1, b: String? = nil, b2: String? = "foo") {
				self.a = a
				self.a2 = a2
				self.b = b
				self.b2 = b2
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}
}
#else
final class InitMacroTests: XCTestCase {
	func testMacro() throws {
		throw XCTSkip("macros are only supported when running tests for the host platform")
	}
}
#endif
