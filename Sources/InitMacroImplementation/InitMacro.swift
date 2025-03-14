import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct InitMacro {
	var members: [Member]

	init(declaration: some DeclGroupSyntax) throws {
		members = declaration.memberBlock.members.compactMap(Member.init(_:))
	}

	public var initFunction: DeclSyntax {
		"""
		init(\(raw: members.map { "\($0.name): \($0.type)" }.joined(separator: ", "))) {
			\(raw: members.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n"))
		}
		"""
	}

	struct Member {
		var name: String
		var type: String
		var defaultValue: String?
	}
}

extension InitMacro.Member {
	init?(_ member: MemberBlockItemListSyntax.Element) {
		let tokens = member.tokens(viewMode: .sourceAccurate)
		var iterator = tokens.makeIterator()

		var hasName = false
		var hasType = false

		name = ""
		type = ""

		loop: while let item = iterator.next() {
			guard case let .keyword(keyword) = item.tokenKind
			else { continue }

			guard keyword == .let || keyword == .var
			else { continue }

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
