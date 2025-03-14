import InitMacro

@Init
public struct Foo {
	var a: Int
	var b: String

	func foo() -> String {
		""
	}
}

@Init
public class FooC {
	var a: Int
	var b: String

	func foo() -> String {
		""
	}
}

@Init
public actor FooA {
	var a: Int
	var b: String

	func foo() -> String {
		""
	}
}
