import SwiftSyntax

enum VariableType {
	case `let`
	case `var`

	init?(_ token: TokenSyntax) {
		switch token.tokenKind {
		case .keyword(.var): self = .var
		case .keyword(.let): self = .let
		default: return nil
		}
	}
}
