import SwiftSyntax
import SwiftSyntaxMacros

public struct OmitFromInitMacro: PeerMacro, NamedAttachedMacro {
	public static let name = "OmitFromInit"

	public static func expansion(
		of node: SwiftSyntax.AttributeSyntax,
		providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
		in context: some SwiftSyntaxMacros.MacroExpansionContext,
	) throws -> [SwiftSyntax.DeclSyntax] {
		guard
			let varDecl = declaration.as(VariableDeclSyntax.self),
			!varDecl.bindings.isEmpty
		else { return [] }

		let initConfig = try InitMacro(parseConfigData: varDecl)

		for member in initConfig.members {
			guard member.defaultValue != nil
			else {
				throw MacroExpansionErrorMessage("Omitted properties require a default value.")
			}
		}

		return []
	}
}
