import SwiftSyntax

protocol NamedAttachedMacro {
	static var name: String { get }
}

extension VariableDeclSyntax {
	func attribute(of type: NamedAttachedMacro.Type) -> AttributeSyntax? {
		attributes
			.compactMap { $0.as(AttributeSyntax.self) }
			.first {
				$0.attributeName.as(IdentifierTypeSyntax.self)?.description == type.name
			}
	}

	func contains(attribute type: NamedAttachedMacro.Type) -> Bool {
		attribute(of: type) != nil
	}
}

extension AttributeListSyntax {
	func contains(_ type: NamedAttachedMacro.Type) -> Bool {
		return contains { $0.name == type.name }
	}
}

extension AttributeSyntax {
	var name: String? {
		attributeName.as(IdentifierTypeSyntax.self)?.name.text
	}
}

extension AttributeListSyntax.Element {
	var name: String? {
		switch self {
		case let .attribute(attr):
			attr.name
		case .ifConfigDecl:
			nil
		}
	}
}
