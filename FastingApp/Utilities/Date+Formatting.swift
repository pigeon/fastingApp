import Foundation

extension Date {
    static func shortTimeString(_ date: Date, is24h: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        if is24h {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.timeStyle = .short
        }
        return formatter.string(from: date)
    }
}
