import Foundation

enum FastingPlan: Equatable, Identifiable {
    case sixteenEight, eighteenSix, twentyFour, custom(hours: Int)

    var id: String { name }

    var fastingHours: Int {
        switch self {
        case .sixteenEight: return 16
        case .eighteenSix: return 18
        case .twentyFour: return 20
        case .custom(let h): return max(1, h)
        }
    }

    var name: String {
        switch self {
        case .sixteenEight: return "16:8"
        case .eighteenSix: return "18:6"
        case .twentyFour: return "20:4"
        case .custom(let h): return "Custom (\(h):\(24 - min(24, h)))"
        }
    }

    static var presets: [FastingPlan] { [.sixteenEight, .eighteenSix, .twentyFour] }
}
