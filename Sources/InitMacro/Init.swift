@attached(member, names: named(init))
public macro Init(access: AccessLevel = .automatic, optionals: OptionalOptions = .implicitDefault) = #externalMacro(module: "InitMacroImplementation", type: "InitMacro")

@attached(peer)
public macro DefaultValue(_ value: Any) = #externalMacro(module: "InitMacroImplementation", type: "DefaultValueMacro")
