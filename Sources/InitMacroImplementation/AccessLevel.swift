import SwiftSyntax

public enum AccessLevel: String {
	case automatic
	case `public`
	case `internal`
	case `fileprivate`
	case `private`
	case `package`

	var keyword: Keyword? {
		switch self {
		case .automatic: nil
		case .public: .public
		case .internal: .internal
		case .fileprivate: .fileprivate
		case .private: .private
		case .package: .package
		}
	}
}
