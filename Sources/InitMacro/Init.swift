@attached(member, names: named(init))
public macro Init(access: AccessLevel = .automatic) = #externalMacro(module: "InitMacroImplementation", type: "InitMacro")
