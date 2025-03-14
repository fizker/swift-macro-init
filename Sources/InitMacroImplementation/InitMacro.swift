import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct InitMacro {
	var access: DeclModifierListSyntax.Element?
	var members: [Member]

	init(declaration: some DeclGroupSyntax) throws {
		access = Self.findAccess(declaration)
		members = declaration.memberBlock.members.compactMap(Member.init(_:))
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

	struct Member {
		var name: String
		var type: String
		var defaultValue: String?

		var asParameter: String {
			let base = "\(name): \(type)"
			if let defaultValue = defaultValue {
				return "\(base) = \(defaultValue)"
			} else {
				return base
			}
		}
	}
}

extension InitMacro.Member {
	init?(_ member: MemberBlockItemListSyntax.Element) {
		let tokens = member.tokens(viewMode: .sourceAccurate)
		var iterator = tokens.makeIterator()

		var hasName = false
		var hasType = false

		enum `Type` {
			case `let`
			case `var`
		}
		var varType: `Type`?

		name = ""
		type = ""

		loop: while let item = iterator.next() {
			guard case let .keyword(keyword) = item.tokenKind
			else { continue }

			guard keyword == .let || keyword == .var
			else { continue }

			varType = keyword == .let ? .let : .var

			break
		}

		while let item = iterator.next() {
			guard case let .identifier(name) = item.tokenKind
			else { continue }

			self.name = name
			hasName = true
			break
		}
		while let item = iterator.next() {
			guard case let .identifier(type) = item.tokenKind
			else { continue }

			self.type = type
			hasType = true
			break
		}

		while let item = iterator.next() {
			guard .equal == item.tokenKind
			else { continue }

			var defaultValue = ""

			while let token = iterator.next() {
				defaultValue += token.text
			}

			self.defaultValue = defaultValue
			break
		}

		guard defaultValue == nil || varType == .var
		else { return nil }

		guard hasName && hasType
		else { return nil }
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
