import SwiftSyntax
import SwiftSyntaxMacros

protocol NamedAttachedMacro {
	static var name: String { get }
}

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

		guard nil == varDecl.attribute(of: OmitFromInitMacro.self)
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

extension VariableDeclSyntax {
	func attribute(of type: (some NamedAttachedMacro).Type) -> AttributeSyntax? {
		attributes
			.compactMap { $0.as(AttributeSyntax.self) }
			.first {
				$0.attributeName.as(IdentifierTypeSyntax.self)?.description == type.name
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

	throw MacroExpansionErrorMessage("Only basic implicit types can be inferred. All others should be specified explicitly.")
}
