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
	DefaultInitValueMacro.name: DefaultInitValueMacro.self,
	OmitFromInitMacro.name: OmitFromInitMacro.self,
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

	func test__init__propertyHaveDidSetBlock__initIsInternal_allFieldsIncluded() async throws {
		assertMacroExpansion("""
		@Init()
		struct Foo {
			var a: String
			var b: Int {
				didSet {}
			}
		}
		""",
		expandedSource: """
		struct Foo {
			var a: String
			var b: Int {
				didSet {}
			}

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
			var a: String { get { "" } }
			var b: Int { 1 }
		}
		""",
		expandedSource: """
		struct Foo {
			var a: String { get { "" } }
			var b: Int { 1 }

			init() {

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

	func test__init__struct_membersHasDefaultValues_membersAreOmitted__membersAreOmitted() async throws {
		assertMacroExpansion("""
		@Init()
		struct Foo {
			@OmitFromInit
			var a: String = ""
			@OmitFromInit
			var b: Int = 1
		}
		""",
		expandedSource: """
		struct Foo {
			var a: String = ""
			var b: Int = 1

			init() {

			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__struct_membersHaveNoDefaultValues_membersAreOmitted__diagnosticRaised() async throws {
		assertMacroExpansion("""
		@Init()
		struct Foo {
			@OmitFromInit
			let a: String
			@OmitFromInit
			var b: Int
		}
		""",
		expandedSource: """
		struct Foo {
			let a: String
			var b: Int

			init() {

			}
		}
		""",
		diagnostics: [
			DiagnosticSpec(message: "Omitted properties require a default value.", line: 3, column: 2),
			DiagnosticSpec(message: "Omitted properties require a default value.", line: 5, column: 2),
		], macros: testMacros, indentationWidth: .tabs(1))
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

	func test__init__letHasDefaultValueAttribute_varHasDefaultValueAttribute__initIsIncludingMember() async throws {
		assertMacroExpansion("""
		@Init
		struct Foo {
			@DefaultInitValue("")
			let a: String
			@DefaultInitValue(1)
			var b: Int
		}
		""",
		expandedSource: """
		struct Foo {
			let a: String
			var b: Int

			init(a: String = "", b: Int = 1) {
				self.a = a
				self.b = b
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__varHaveDefaultValue_varHasDefaultValueAttribute__errorIsShown() async throws {
		assertMacroExpansion("""
		@Init
		struct Foo {
			@DefaultInitValue(2)
			var a: Int = 1
		}
		""",
		expandedSource: """
		struct Foo {
			var a: Int = 1

			init(a: Int = 1) {
				self.a = a
			}
		}
		""",
		diagnostics: [
			DiagnosticSpec(message: "@DefaultInitValue is not allowed if the property already have a value.", line: 3, column: 2),
		], macros: testMacros, indentationWidth: .tabs(1))
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

	func test__init__optional_explicitDefaultIsSet__initHasDefaultValueAsNil() async throws {
		assertMacroExpansion("""
		@Init(optionals: .explicitDefault)
		class Foo {
			var a: Int?
			var a2: Int? = 1
			var a3: Int? = nil
			var b: String?
			var b2: String? = "foo"
			var b3: String? = nil
		}
		""",
		expandedSource: """
		class Foo {
			var a: Int?
			var a2: Int? = 1
			var a3: Int? = nil
			var b: String?
			var b2: String? = "foo"
			var b3: String? = nil

			init(a: Int?, a2: Int? = 1, a3: Int? = nil, b: String?, b2: String? = "foo", b3: String? = nil) {
				self.a = a
				self.a2 = a2
				self.a3 = a3
				self.b = b
				self.b2 = b2
				self.b3 = b3
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
