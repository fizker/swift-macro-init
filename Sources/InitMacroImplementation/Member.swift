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
	init?(_ member: MemberBlockItemListSyntax.Element, optionals: OptionalOptions) throws {
		guard
			let varDecl = member.decl.as(VariableDeclSyntax.self),
			let varType = VariableType(varDecl.bindingSpecifier),
			let binding = varDecl.bindings.first,
			!isComputed(binding)
		else { return nil }

		name = binding.pattern.trimmed
		type = try inferType(binding)
		defaultValue = binding.initializer?.value.trimmedDescription

		if defaultValue == nil && optionals == .implicitDefault && type.type.is(OptionalTypeSyntax.self) {
			defaultValue = "nil"
		}

		if varType == .let && defaultValue != nil {
			return nil
		}

		if let defaultValueAttribute = varDecl.attributes.first(where: { $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description == "DefaultValue" }) {
			let customKeyValue = defaultValueAttribute.as(AttributeSyntax.self)!
				.arguments!.as(LabeledExprListSyntax.self)!
				.first!
				.expression

			if defaultValue == nil {
				defaultValue = customKeyValue.description
			} else {
				// error is raised by DefaultValueMacro
			}
		}
	}
}

func isComputed(_ binding: PatternBindingSyntax) -> Bool {
	// Computed vars have this set
	guard let accessor = binding.accessorBlock
	else { return false }

	// Inline-get (i.e. var a: Int { 1 })
	guard let accessorList = accessor.accessors.as(AccessorDeclListSyntax.self)
	else { return true }

	// Explicit get (i.e. var a: Int { get { 1 } })
	guard !accessorList.contains(where: { $0.accessorSpecifier.tokenKind == .keyword(.get) })
	else { return true }

	// If there is no get, this cannot be computed
	return false
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
