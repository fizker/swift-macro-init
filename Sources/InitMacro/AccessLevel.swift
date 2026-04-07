/// The access level that the generated `init()` will have.
public enum AccessLevel {
	/// Inherit the access level from the type itself.
	case automatic

	/// Enforce `public` access level.
	///
	/// This is also the default if the type is `open class`.
	///
	/// Note that the `init()` can never be more accessible than the type.
	/// This means that `internal struct Foo { public init() {} }` will still only be accessible internally.
	case `public`

	/// Enforce `internal` access level.
	case `internal`

	/// Enforce `fileprivate` access level.
	case `fileprivate`

	/// Enforce `private` access level.
	case `private`

	/// Enforce `package` access level.
	///
	/// Note that the `init()` can never be more accessible than the type.
	/// This means that `internal struct Foo { package init() {} }` will still only be accessible internally.
	case `package`
}
