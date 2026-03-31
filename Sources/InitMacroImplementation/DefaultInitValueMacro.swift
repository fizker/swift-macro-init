import SwiftSyntax
import SwiftSyntaxMacros

public struct DefaultInitValueMacro: PeerMacro {
	public static let name = "DefaultInitValue"

	public static func expansion(
		of node: SwiftSyntax.AttributeSyntax,
		providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
		in context: some SwiftSyntaxMacros.MacroExpansionContext,
	) throws -> [SwiftSyntax.DeclSyntax] {
		guard
			let varDecl = declaration.as(VariableDeclSyntax.self),
			let binding = varDecl.bindings.first
		else { return [] }

		guard !isComputed(binding)
		else { throw MacroExpansionErrorMessage("Computed values cannot have a default") }

		let defaultValue = binding.initializer?.value.trimmedDescription
		guard defaultValue == nil
		else {
			throw MacroExpansionErrorMessage("@DefaultInitValue is not allowed if the property already have a value.")
		}

		return []
	}
}
