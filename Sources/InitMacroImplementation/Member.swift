import SwiftSyntax
import SwiftSyntaxMacros

struct Member {
	var name: PatternSyntax
	var type: TypeAnnotationSyntax
	var defaultValue: String?

	var asParameter: String {
		let base = "\(name)\(type)"
		if let defaultValue = defaultValue {
			return "\(base) = \(defaultValue)"
		} else {
			return base
		}
	}
}

extension Member {
	init?(_ member: MemberBlockItemListSyntax.Element) throws {
		guard
			let varDecl = member.decl.as(VariableDeclSyntax.self),
			let varType = VariableType(varDecl.bindingSpecifier),
			let binding = varDecl.bindings.first,

			// Computed vars have this set
			binding.accessorBlock == nil
		else { return nil }

		name = binding.pattern.trimmed
		type = try inferType(binding)
		defaultValue = binding.initializer?.value.trimmedDescription

		if defaultValue != nil && varType == .let {
			return nil
		}
	}
}

func inferType(_ binding: PatternBindingSyntax) throws -> TypeAnnotationSyntax {
	if let type = binding.typeAnnotation {
		return type.trimmed
	}

	guard let initializer = binding.initializer
	else {
		throw MacroExpansionErrorMessage("Type information missing")
	}

	let ident: String

	if initializer.value.is(IntegerLiteralExprSyntax.self) {
		ident = "Int"
	} else if initializer.value.is(BooleanLiteralExprSyntax.self) {
		ident = "Bool"
	} else if initializer.value.is(StringLiteralExprSyntax.self) {
		ident = "String"
	} else if initializer.value.is(FloatLiteralExprSyntax.self) {
		// FloatLiteralExprSyntax is inferred as `Double` by the compiler.
		ident = "Double"
	} else {
		throw MacroExpansionErrorMessage("Only basic literal types can be inferred. All others should be specified explicitly.")
	}

	return TypeAnnotationSyntax(type: IdentifierTypeSyntax(name: .identifier(ident)))
}
