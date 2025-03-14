@attached(member, names: named(init))
public macro Init() = #externalMacro(module: "InitMacroImplementation", type: "InitMacro")
