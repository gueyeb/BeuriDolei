import Foundation

enum PlankVariant: String, CaseIterable, Codable, Identifiable {
    case classic
    case sideLeft
    case sideRight
    case straightArms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic:
            return "Classique"
        case .sideLeft:
            return "Latérale G"
        case .sideRight:
            return "Latérale D"
        case .straightArms:
            return "Bras tendus"
        }
    }

    var shortTitle: String {
        switch self {
        case .classic:
            return "Classique"
        case .sideLeft:
            return "Gauche"
        case .sideRight:
            return "Droite"
        case .straightArms:
            return "Tendus"
        }
    }

    var systemImage: String {
        switch self {
        case .classic:
            return "rectangle.compress.vertical"
        case .sideLeft:
            return "arrow.left"
        case .sideRight:
            return "arrow.right"
        case .straightArms:
            return "rectangle.expand.vertical"
        }
    }

    var detail: String {
        switch self {
        case .classic:
            return "Planche isométrique standard."
        case .sideLeft:
            return "Gainage latéral côté gauche."
        case .sideRight:
            return "Gainage latéral côté droit."
        case .straightArms:
            return "Planche haute, bras tendus."
        }
    }
}
