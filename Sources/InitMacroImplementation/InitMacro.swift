import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// This is an internal macro. It is added by ``InitMacro`` and should never be exposed outside
struct InitConfigDataMacro: NamedAttachedMacro {
	static let name = "InitConfigData"
}

extension InitConfigDataMacro: PeerMacro {
	public static func expansion(
		of node: SwiftSyntax.AttributeSyntax,
		providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
		in context: some SwiftSyntaxMacros.MacroExpansionContext
	) throws -> [SwiftSyntax.DeclSyntax] {
		[]
	}
}

public struct InitMacro {
	var access: DeclModifierSyntax?
	var optionals: OptionalOptions
	var members: [Member]

	init(node: AttributeSyntax, declaration: some DeclGroupSyntax) throws {
		try self.init(
			access: find("access", in: node.arguments) ?? .automatic,
			optionals: find("optionals", in: node.arguments) ?? .implicitDefault,
			declaration: declaration,
		)
	}

	init(
		access: AccessLevel,
		optionals: OptionalOptions,
		declaration: some DeclGroupSyntax,
	) throws {
		self.access = access.keyword.map { DeclModifierSyntax(name: TokenSyntax.keyword($0)) } ?? Self.findAccess(declaration)
		self.access?.trailingTrivia = .space
		self.optionals = optionals
		members = try declaration.memberBlock.members.flatMap { try Member.members(for: $0, optionals: optionals) }
	}

	public var initFunction: DeclSyntax {
		let members = members.filter(\.shouldBeIncluded)
		return """
		\(access)init(\(raw: members.map(\.asParameter).joined(separator: ", "))) {
			\(raw: members.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n"))
		}
		"""
	}

	/// Converts the configuration of this attribute into an ``InitConfigDataMacro`` attribute meant to go on a member.
	var configurationDataAttribute: AttributeSyntax {
		"@\(raw: InitConfigDataMacro.name)(optionals: .\(raw: optionals.rawValue))"
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

extension InitMacro: MemberAttributeMacro {
	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingAttributesFor member: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext,
	) throws -> [AttributeSyntax] {
		// node is @Init
		// member is var
		guard
			let varDecl = member.as(VariableDeclSyntax.self),
			varDecl.attributes.contains(OmitFromInitMacro.self)
		else { return [] }

		let `init` = try InitMacro(node: node, declaration: declaration)

		return [
			`init`.configurationDataAttribute,
		]
	}

	init(parseConfigData varDecl: VariableDeclSyntax) throws {
		let configData = varDecl.attribute(of: InitConfigDataMacro.self)

		self.optionals = configData.flatMap { find("optionals", in: $0.arguments) } ?? .implicitDefault
		self.members = try Member.members(for: varDecl, optionals: optionals)
	}
}

extension InitMacro: MemberMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		let v = try InitMacro(node: node, declaration: declaration)

		return [v.initFunction]
	}
}

private func find<Type: RawRepresentable>(_ label: String, in arguments: AttributeSyntax.Arguments?) -> Type?
	where Type.RawValue == String
{
	guard
		let arguments = arguments?.as(LabeledExprListSyntax.self),
		let arg = arguments.first(where: { $0.label?.text == label }),
		let memberAccess = arg.expression.as(MemberAccessExprSyntax.self)
	else { return nil }

	return Type(rawValue: memberAccess.declName.baseName.text)
}
