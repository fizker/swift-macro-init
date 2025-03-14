import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct InitMacro {
	var access: DeclModifierSyntax?
	var members: [Member]

	init(access: AccessLevel, declaration: some DeclGroupSyntax) throws {
		self.access = access.keyword.map { DeclModifierSyntax(name: TokenSyntax.keyword($0)) } ?? Self.findAccess(declaration)
		self.access?.trailingTrivia = .space
		members = try declaration.memberBlock.members.compactMap(Member.init(_:))
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
		let v = try InitMacro(access: find("access", in: node.arguments) ?? .automatic, declaration: declaration)

		return [v.initFunction]
	}

	private static func find(_ label: String, in arguments: AttributeSyntax.Arguments?) -> AccessLevel? {
		guard
			let arguments = arguments?.as(LabeledExprListSyntax.self),
			let arg = arguments.first(where: { $0.label?.text == label }),
			let memberAccess = arg.expression.as(MemberAccessExprSyntax.self)
		else { return nil }

		return AccessLevel(rawValue: memberAccess.declName.baseName.text)
	}
}
