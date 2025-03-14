import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct InitMacro {
	var access: DeclModifierListSyntax.Element?
	var members: [Member]

	init(declaration: some DeclGroupSyntax) throws {
		access = Self.findAccess(declaration)
		members = try declaration.memberBlock.members.compactMap(Member.init(_:))
	}

	public var initFunction: DeclSyntax {
		"""
		\(access)init(\(raw: members.map(\.asParameter).joined(separator: ", "))) {
			\(raw: members.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n"))
		}
		"""
	}

	static func findAccess(_ declaration: some DeclGroupSyntax) -> DeclModifierListSyntax.Element? {
		return declaration.modifiers.first {
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
	}

}

extension InitMacro: MemberMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		let v = try InitMacro(declaration: declaration)

		return [v.initFunction]
	}
}
