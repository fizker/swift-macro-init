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
	func generatedInit__somePropertiesOnSingleDeclaration_functionPresent__propertiesIsSetThroughInit() async throws {
		@Init
		struct Foo {
			var a: Int, b: String

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
			@DefaultInitValue(1)
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
	func generatedInit__defaultValues_relyingOnLiteralExpression__defaultValuesAreRespected() async throws {
		@Init
		struct Foo {
			@DefaultInitValue([1])
			var bar: Set<Int>
		}

		_ = Foo()
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
	func generatedInit__propertyContainsBlock__funcIsEscaped() async throws {
		@Init
		struct Foo {
			var a: (String) -> Int
		}

		let instance = Foo { $0.count }
		#expect(instance.a("foo") == 3)
	}

	@Test
	func generatedInit__propertyContainsArrayOfBlocks__funcIsEscaped() async throws {
		@Init
		struct Foo {
			var a: [(String) -> Int]
		}

		let instance = Foo(a: [{ $0.count }])
		#expect(instance.a.map { $0("foo") } == [3])
	}

	@Test
	func generatedInit__propertyContainsSendableBlock__funcIsEscaped() async throws {
		@Init
		struct Foo {
			var a: @Sendable (String) -> Int
		}

		let instance = Foo(a: { $0.count })
		#expect(instance.a("foo") == 3)
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

	@Test
	func generatedInit__onePropertyOmitted__otherPropertyIsAvailable() async throws {
		@Init
		struct Foo {
			@OmitFromInit
			var a: Int = 1
			var b: String = ""
		}

		let instance = Foo(b: "foo")
		#expect(instance.a == 1)
		#expect(instance.b == "foo")
	}

	@Test
	func generatedInit__allPropertiesOmitted__noPropertiesAvailable() async throws {
		@Init
		struct Foo {
			@OmitFromInit
			var a: Int = 1, b: String = ""
		}

		let instance = Foo()
		#expect(instance.a == 1)
		#expect(instance.b == "")
	}

	@Test
	func generatedInit__letHaveDefaultValueButNoType_typeIsComplex__varIsOmitted() async throws {
		struct Bar {}

		@Init
		struct Foo {
			let a = Bar()
		}
	}

	@Test
	func generatedInit__propertyContainsRestrictedKeyword__initStillWorks() async throws {
		@Init
		struct Foo {
			var `class`: String
		}
	}
}
