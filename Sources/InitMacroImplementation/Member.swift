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
	static func members(for item: MemberBlockItemListSyntax.Element, optionals: OptionalOptions) throws -> [Member] {
		guard
			let varDecl = item.decl.as(VariableDeclSyntax.self),
			let varType = VariableType(varDecl.bindingSpecifier)
		else { return [] }

		guard varDecl.attribute(of: DefaultInitValueMacro.self) == nil || varDecl.bindings.count == 1
		else { throw MacroExpansionErrorMessage("@\(DefaultInitValueMacro.name) is ambivalent") }

		return try varDecl.bindings.compactMap { try Member(varDecl: varDecl, varType: varType, binding: $0, optionals: optionals) }
	}

	private init?(varDecl: VariableDeclSyntax, varType: VariableType, binding: PatternBindingSyntax, optionals: OptionalOptions) throws {
		guard !isComputed(binding)
		else { return nil }

		guard !varDecl.contains(attribute: OmitFromInitMacro.self)
		else { return nil }

		name = binding.pattern.trimmed
		defaultValue = binding.initializer?.value.trimmedDescription

		if varType == .let && defaultValue != nil {
			return nil
		}

		type = try inferType(binding)

		if defaultValue == nil && optionals == .implicitDefault && type.type.is(OptionalTypeSyntax.self) {
			defaultValue = "nil"
		}

		if let defaultValueAttribute = varDecl.attribute(of: DefaultInitValueMacro.self) {
			let customKeyValue = defaultValueAttribute
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
		if let `func` = type.type.as(FunctionTypeSyntax.self) {
			return TypeAnnotationSyntax(type: AttributedTypeSyntax(
				// This empty list is necessary to avoid a deprecation warning
				specifiers: [],
				attributes: "@escaping",
				baseType: `func`,
			))
		}
		return type.trimmed
	}

	guard let initializer = binding.initializer
	else {
		throw MacroExpansionErrorMessage("Type information missing")
	}

	let ident = try inferType(initializer.value)
	return TypeAnnotationSyntax(type: IdentifierTypeSyntax(name: .identifier(ident)))
}

func inferType(_ value: ExprSyntax) throws -> String {
	if value.is(IntegerLiteralExprSyntax.self) {
		return "Int"
	} else if value.is(BooleanLiteralExprSyntax.self) {
		return "Bool"
	} else if value.is(StringLiteralExprSyntax.self) {
		return "String"
	} else if value.is(FloatLiteralExprSyntax.self) {
		// FloatLiteralExprSyntax is inferred as `Double` by the compiler.
		return "Double"
	} else if let a = value.as(ArrayExprSyntax.self) {
		let idents = Set(try a.elements.map { try inferType($0.expression) })
		if idents.count == 1, let ident = idents.first {
			return "[\(ident)]"
		}
	}

	if let dict = value.as(DictionaryExprSyntax.self), let elements = dict.content.as(DictionaryElementListSyntax.self) {
		var keyIdents = Set<String>()
		var valueIdents = Set<String>()
		for element in elements {
			keyIdents.insert(try inferType(element.key))
			valueIdents.insert(try inferType(element.value))
		}

		if keyIdents.count == 1 && valueIdents.count == 1, let key = keyIdents.first, let value = valueIdents.first {
			return "[\(key):\(value)]"
		}
	}

	throw MacroExpansionErrorMessage("Only basic implicit types can be inferred. All others should be specified explicitly.")
}
