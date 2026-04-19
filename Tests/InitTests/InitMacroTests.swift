import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(InitMacroImplementation)
@testable import InitMacroImplementation

let testMacros: [String: Macro.Type] = [
	"Init": InitMacro.self,
	DefaultInitValueMacro.name: DefaultInitValueMacro.self,
	OmitFromInitMacro.name: OmitFromInitMacro.self,
	InitConfigDataMacro.name: InitConfigDataMacro.self,
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

	func test__init__struct_simple_defaultAccess_multipleVarsPerType__initIsInternal_allFieldsIncluded() async throws {
		assertMacroExpansion("""
		@Init()
		struct Foo {
			var a: String, b: Int
			let c: String, d: Int
		}
		""",
		expandedSource: """
		struct Foo {
			var a: String, b: Int
			let c: String, d: Int

			init(a: String, b: Int, c: String, d: Int) {
				self.a = a
				self.b = b
				self.c = c
				self.d = d
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__propertyIsFunc__funcIsMarkedAsEscaping() async throws {
		assertMacroExpansion("""
		@Init
		struct Foo {
			var a: (String) -> Int
		}
		""",
		expandedSource: """
		struct Foo {
			var a: (String) -> Int

			init(a: @escaping (String) -> Int) {
				self.a = a
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__propertyIsFunc_propertyIsSendable__funcIsMarkedAsEscaping() async throws {
		assertMacroExpansion("""
		@Init
		struct Foo {
			var a: @Sendable (String) -> Int
		}
		""",
		expandedSource: """
		struct Foo {
			var a: @Sendable (String) -> Int

			init(a: @Sendable @escaping (String) -> Int) {
				self.a = a
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

	func test__init__struct_multipleMembersForOneVar_secondMemberHaveNoDefaultValue_membersAreOmitted__diagnosticRaised() async throws {
		XCTExpectFailure(issueMatcher: {
			$0.compactDescription == """
			failed - Expected 1 diagnostics but received 2:
			3:2: peer macro can only be applied to a single variable
			4:2: peer macro can only be applied to a single variable
			"""
		})

		assertMacroExpansion("""
		@Init()
		struct Foo {
			@OmitFromInit
			var a: String = "", b: Int
		}
		""",
		expandedSource: """
		struct Foo {
			var a: String = "", b: Int

			init() {

			}
		}
		""",
		diagnostics: [
			DiagnosticSpec(message: "Omitted properties require a default value.", line: 3, column: 2),
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

	func test__init__letHasDefaultValueAttribute_varHasDefaultValueAttribute_multipleDeclarationsPerType__errorIsRaised() async throws {
		XCTExpectFailure("assertMacroExpansion() gives different result than actually using the macro", issueMatcher: {
			$0.compactDescription == """
			failed - message does not match
			–@DefaultInitValue can only be attached to a single property
			+peer macro can only be applied to a single variable

			"""
		})

		assertMacroExpansion("""
		@Init
		struct Foo {
			@DefaultInitValue("")
			let a: String, c: String
			@DefaultInitValue(1)
			var b: Int, d: Int
		}
		""",
		expandedSource: """
		struct Foo {
			let a: String, c: String
			var b: Int, d: Int
		}
		""", diagnostics: [
			DiagnosticSpec(message: "@DefaultInitValue can only be attached to a single property", line: 3, column: 2),
			DiagnosticSpec(message: "@DefaultInitValue can only be attached to a single property", line: 5, column: 2),
			DiagnosticSpec(message: "@DefaultInitValue is ambivalent", line: 1, column: 1),
		], macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__letHasDefaultValue_typeIsOmitted_typeIsComplex__letIsOmitted() async throws {
		assertMacroExpansion("""
		struct Bar {}

		@Init
		struct Foo {
			let a = Bar()
		}
		""", expandedSource: """
		struct Bar {}
		struct Foo {
			let a = Bar()

			init() {

			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__varHasOmitFromInitAttribute_multipleDeclarationsPerType__allAreOmitted() async throws {
		XCTExpectFailure("assertMacroExpansion() gives different result than actually using the macro", issueMatcher: {
			$0.compactDescription == """
			failed - Expected 0 diagnostics but received 2:
			3:2: peer macro can only be applied to a single variable
			4:2: peer macro can only be applied to a single variable
			"""
		})

		assertMacroExpansion("""
		@Init
		struct Foo {
			@OmitFromInit
			var a: Int = 1, b: String = ""
			var b: Int, d: Int
		}
		""",
		expandedSource: """
		struct Foo {
			var a: Int = 1, b: String = ""
			var b: Int, d: Int

			init(b: Int, d: Int) {
				self.b = b
				self.d = d
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

	func test__init__struct_memberHasImplicitArrayType_elementsAreBasicTypes__initParameterCorrectlyIncludesMember() async throws {
		assertMacroExpansion("""
		@Init()
		struct Foo {
			var a = [""]
			var b = [1]
			var c = [false]
			var d = [2.3]
		}
		""",
		expandedSource: """
		struct Foo {
			var a = [""]
			var b = [1]
			var c = [false]
			var d = [2.3]

			init(a: [String] = [""], b: [Int] = [1], c: [Bool] = [false], d: [Double] = [2.3]) {
				self.a = a
				self.b = b
				self.c = c
				self.d = d
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__struct_memberHasImplicitDictionaryType_elementsAreBasicTypes__initParameterCorrectlyIncludesMember() async throws {
		assertMacroExpansion("""
		@Init()
		struct Foo {
			var a = ["":""]
			var b = [1:false]
			var c = [2.3:false]
			var d = [2.3:""]
		}
		""",
		expandedSource: """
		struct Foo {
			var a = ["":""]
			var b = [1:false]
			var c = [2.3:false]
			var d = [2.3:""]

			init(a: [String: String] = ["": ""], b: [Int: Bool] = [1: false], c: [Double: Bool] = [2.3: false], d: [Double: String] = [2.3: ""]) {
				self.a = a
				self.b = b
				self.c = c
				self.d = d
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__struct_memberHasComplexImplicitType__errorRaised() async throws {
		assertMacroExpansion("""
		struct Bar {
			var foo: Int
		}

		func baz() -> Int {
			return 1
		}

		@Init()
		struct Foo {
			var b = Bar(foo: 1)
			var c = baz()
		}
		""",
		expandedSource: """
		struct Bar {
			var foo: Int
		}

		func baz() -> Int {
			return 1
		}
		struct Foo {
			var b = Bar(foo: 1)
			var c = baz()
		}
		""", diagnostics: [
			DiagnosticSpec(message: "Only basic implicit types can be inferred. All others should be specified explicitly.", line: 9, column: 1),
		], macros: testMacros, indentationWidth: .tabs(1))
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

			let c: Int?
			let d: String?
		}
		""",
		expandedSource: """
		class Foo {
			var a: Int?
			var a2: Int? = 1
			var b: String?
			var b2: String? = "foo"

			let c: Int?
			let d: String?

			init(a: Int? = nil, a2: Int? = 1, b: String? = nil, b2: String? = "foo", c: Int? = nil, d: String? = nil) {
				self.a = a
				self.a2 = a2
				self.b = b
				self.b2 = b2
				self.c = c
				self.d = d
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

	func test__init__optional_varIsOmitted__initIsOmittingVar() async throws {
		assertMacroExpansion("""
		@Init
		struct Foo {
			var a: Int?
			@OmitFromInit
			var b: Int?
		}
		""", expandedSource: """
		struct Foo {
			var a: Int?
			var b: Int?

			init(a: Int? = nil) {
				self.a = a
			}
		}
		""", macros: testMacros, indentationWidth: .tabs(1))
	}

	func test__init__optional_varIsOmitted_optionalsMustBeExplicit__diagnosticIsRaised() async throws {
		assertMacroExpansion("""
		@Init(optionals: .explicitDefault)
		struct Foo {
			var a: Int?
			@OmitFromInit
			var b: Int?
		}
		""", expandedSource: """
		struct Foo {
			var a: Int?
			var b: Int?

			init(a: Int?) {
				self.a = a
			}
		}
		""", diagnostics: [
			DiagnosticSpec(message: "Omitted properties require a default value.", line: 4, column: 2),
		], macros: testMacros, indentationWidth: .tabs(1))
	}
}
#else
final class InitMacroTests: XCTestCase {
	func testMacro() throws {
		throw XCTSkip("macros are only supported when running tests for the host platform")
	}
}
#endif
