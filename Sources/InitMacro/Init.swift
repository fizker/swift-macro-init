@attached(member, names: named(init))
public macro Init(access: AccessLevel = .automatic, optionals: OptionalOptions = .implicitDefault) = #externalMacro(module: "InitMacroImplementation", type: "InitMacro")

@attached(peer)
public macro DefaultInitValue(_ value: Any) = #externalMacro(module: "InitMacroImplementation", type: "DefaultInitValueMacro")

@attached(peer)
public macro OmitFromInitMacro() = #externalMacro(module: "InitMacroImplementation", type: "OmitFromInitMacroMacro")
