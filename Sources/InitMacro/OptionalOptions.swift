/// Options for handling optional properties.
public enum OptionalOptions {
	/// If no explicit default is given, `nil` is implicit.
	///
	/// ```swift
	/// @Init(optionals: .implicitDefault)
	/// struct Foo {
	/// 	var a: Int?
	/// }
	/// ```
	/// becomes
	/// ```swift
	/// struct Foo {
	/// 	var a: Int?
	///
	/// 	init(a: Int? = nil) {
	/// 		self.a = a
	/// 	}
	/// }
	/// ```
	case implicitDefault

	/// If no explicit default is given, the optional becomes required.
	///
	/// ```swift
	/// @Init(optionals: .explicitDefault)
	/// struct Foo {
	/// 	var a: Int?
	/// }
	/// ```
	/// becomes
	/// ```swift
	/// struct Foo {
	/// 	var a: Int?
	///
	/// 	init(a: Int?) {
	/// 		self.a = a
	/// 	}
	/// }
	/// ```
	case explicitDefault
}
