/// Generates an init for the given type.
///
/// The init-function will by default have the same access-level as the type itself. E.g. `@Init public struct ...` generates a `public init()`.
///
/// ```swift
/// @Init(access: .fileprivate, optionals: .explicitDefault) struct Foo {
/// 	var a: Int?
///
/// 	// generated init
/// 	fileprivate init(a: Int?) {
/// 		...
/// 	}
/// }
/// ```
///
/// - Parameters
///   - access: The wanted access-level. This defaults to `.automatic`, which will be the same as the type itself.
///   - optionals: How to handle optional values. The default is `.implicitDefault`.
@attached(member, names: named(init))
public macro Init(access: AccessLevel = .automatic, optionals: OptionalOptions = .implicitDefault) = #externalMacro(module: "InitMacroImplementation", type: "InitMacro")

/// Sets a default value.
///
/// Use this macro to give `let`-values an overrideable default value in the `init()` function.
///
/// It can be used as an alternative for `var`-values as well.
///
/// ```swift
/// @Init struct Foo {
/// 	var a: Int = 1
/// 	@DefaultInitValue(2) var b: Int
/// 	let c: Int = 3
/// 	let d: Int
/// 	@DefaultInitValue(5) let e: Int
///
/// 	// generated init
/// 	init(a: Int = 1, b: Int = 2, d: Int, e: Int = 5) {
/// 		...
/// 	}
/// }
/// ```
///
/// Any valid value can be set here. It is handled and enforced by the compiler, so any `ExpressibleBy*Literal` constructs are respected.
///
/// Note: To the Swift compiler, properties written as `let foo = ...` are constants and cannot be set in the constructor.
///
/// - parameter value: The default value for the property.
@attached(peer)
public macro DefaultInitValue(_ value: Any) = #externalMacro(module: "InitMacroImplementation", type: "DefaultInitValueMacro")

/// Properties marked with this macro will be omitted from the generated init-function.
///
/// They must have a default value, since they will otherwise not be initialized.
///
/// ```swift
/// @Init struct Foo {
/// 	var a: Int
/// 	@OmitFromInit var b: Int = 1
///
/// 	// Generated init
/// 	init(a: Int) {
/// 		...
/// 	}
/// }
/// ```
@attached(peer)
public macro OmitFromInit() = #externalMacro(module: "InitMacroImplementation", type: "OmitFromInitMacro")
