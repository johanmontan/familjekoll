import SwiftUI

enum FamilyCategory: String, Codable, CaseIterable, Hashable, Sendable {
    case johan
    case emma
    case ia
    case allie
    case annat

    var displayName: String {
        switch self {
        case .johan: "Johan"
        case .emma: "Emma"
        case .ia: "Ia"
        case .allie: "Allie"
        case .annat: "Annat"
        }
    }

    var shortName: String {
        switch self {
        case .annat: "Jobb/annat"
        default: displayName
        }
    }

    var symbolName: String {
        switch self {
        case .johan: "figure.run"
        case .emma: "cat.fill"
        case .ia: "star.fill"
        case .allie: "heart.fill"
        case .annat: "briefcase.fill"
        }
    }

    var color: Color {
        switch self {
        case .johan:
            Color(uiColor: UIColor { traits in
                if traits.userInterfaceStyle == .dark {
                    return UIColor(red: 0.34, green: 0.62, blue: 0.98, alpha: 1)
                }
                return UIColor(red: 0.16, green: 0.42, blue: 0.76, alpha: 1)
            })
        case .emma: Color(red: 0.80, green: 0.31, blue: 0.49)
        case .ia: Color(red: 0.95, green: 0.60, blue: 0.16)
        case .allie: Color(red: 0.47, green: 0.34, blue: 0.76)
        case .annat: Color(red: 0.22, green: 0.55, blue: 0.44)
        }
    }
}
