import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct InitMacro {
	var access: DeclModifierSyntax?
	var optionals: OptionalOptions
	var members: [Member]

	init(
		access: AccessLevel,
		optionals: OptionalOptions,
		declaration: some DeclGroupSyntax,
	) throws {
		self.access = access.keyword.map { DeclModifierSyntax(name: TokenSyntax.keyword($0)) } ?? Self.findAccess(declaration)
		self.access?.trailingTrivia = .space
		self.optionals = optionals
		members = try declaration.memberBlock.members.compactMap { try Member($0, optionals: optionals) }
	}

	public var initFunction: DeclSyntax {
		"""
		\(access)init(\(raw: members.map(\.asParameter).joined(separator: ", "))) {
			\(raw: members.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n"))
		}
		"""
	}

	static func findAccess(_ declaration: some DeclGroupSyntax) -> DeclModifierSyntax? {
		var element = declaration.modifiers.first {
			switch $0.name.tokenKind {
			case
				.keyword(.public),
				.keyword(.open),
				.keyword(.internal),
				.keyword(.private),
				.keyword(.package),
				.keyword(.fileprivate):
				return true
			default:
				return false
			}
		}

		if element?.name.tokenKind == .keyword(.open) {
			// `open` is not supported; we change it to `public`
			element?.name.tokenKind = .keyword(.public)
		}

		return element?.trimmed
	}

}

extension InitMacro: MemberMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		let v = try InitMacro(
			access: find("access", in: node.arguments) ?? .automatic,
			optionals: find("optionals", in: node.arguments) ?? .implicitDefault,
			declaration: declaration,
		)

		return [v.initFunction]
	}

	private static func find<Type: RawRepresentable>(_ label: String, in arguments: AttributeSyntax.Arguments?) -> Type?
		where Type.RawValue == String
	{
		guard
			let arguments = arguments?.as(LabeledExprListSyntax.self),
			let arg = arguments.first(where: { $0.label?.text == label }),
			let memberAccess = arg.expression.as(MemberAccessExprSyntax.self)
		else { return nil }

		return Type(rawValue: memberAccess.declName.baseName.text)
	}
}
