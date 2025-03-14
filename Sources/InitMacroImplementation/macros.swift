import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct InitMacroPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		InitMacro.self,
	]
}
