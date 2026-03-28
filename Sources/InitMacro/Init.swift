@attached(member, names: named(init))
public macro Init(access: AccessLevel = .automatic, optionals: OptionalOptions = .implicitDefault) = #externalMacro(module: "InitMacroImplementation", type: "InitMacro")
