import InitMacro
import Testing

struct Tests {
	@Test
	func generatedInit__someProperties_functionPresent__propertiesIsSetThroughInit() async throws {
		@Init
		struct Foo {
			var a: Int
			var b: String

			func foo() -> String {
				""
			}
		}

		let instance = Foo(a: 1, b: "foo")
		#expect(instance.a == 1)
		#expect(instance.b == "foo")
		#expect(instance.foo() == "")
	}

	@Test
	func generatedInit__accessLevelGiven__propertiesAreSet() async throws {
		@Init(access: .package)
		struct Foo {
			var a: Int
			var b: String

			func foo() -> String {
				""
			}
		}

		let instance = Foo(a: 1, b: "foo")
		#expect(instance.a == 1)
		#expect(instance.b == "foo")
		#expect(instance.foo() == "")
	}

	@Test
	func generatedInit__letProperties__allPropertiesCanBeSet_defaultValuesAreRespected() async throws {
		@Init
		class Foo {
			let a: Int
			var b: String
		}

		let instance = Foo(a: 1, b: "foo")
		#expect(instance.a == 1)
		#expect(instance.b == "foo")
	}

	@Test
	func generatedInit__letProperties_defaultValues__allPropertiesCanBeSet_defaultValuesAreRespected() async throws {
		@Init
		class Foo {
			@DefaultValue(1)
			let a: Int
			var b: String = "foo"
		}

		let instance1 = Foo()
		#expect(instance1.a == 1)
		#expect(instance1.b == "foo")

		let instance2 = Foo(a: 2, b: "bar")
		#expect(instance2.a == 2)
		#expect(instance2.b == "bar")
	}

	@Test
	func generatedInit__optionalProperties__allPropertiesCanBeSet_defaultValuesAreRespected() async throws {
		@Init
		class Foo {
			var a: Int?
		}

		let instance1 = Foo()
		#expect(instance1.a == nil)

		let instance2 = Foo(a: 2)
		#expect(instance2.a == 2)

		let instance3 = Foo(a: nil)
		#expect(instance3.a == nil)
	}

	@Test
	func generatedInit__optionalProperties_optionForExplicitDefaultsOnly__allPropertiesMustBeSet() async throws {
		@Init(optionals: .explicitDefault)
		class Foo {
			var a: Int?
		}

		let instance2 = Foo(a: 2)
		#expect(instance2.a == 2)

		let instance3 = Foo(a: nil)
		#expect(instance3.a == nil)
	}

	@Test
	func generatedInit__propertyIsComputed__itIsOmittedInInit() async throws {
		@Init
		struct Foo {
			var a: Int {
				get { 1 }
			}
		}

		_ = Foo()
	}

	@Test
	func generatedInit__propertyHaveDidSet__itIsIncludedInInit() async throws {
		@Init
		struct Foo {
			var a: Int {
				didSet {}
			}
		}

		_ = Foo(a: 1)
	}
}
