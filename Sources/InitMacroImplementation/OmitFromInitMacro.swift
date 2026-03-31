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
			let binding = varDecl.bindings.first
		else { return [] }

		let defaultValue = binding.initializer?.value.trimmedDescription
		guard defaultValue != nil
		else {
			throw MacroExpansionErrorMessage("Omitted properties require a default value.")
		}

		return []
	}
}
