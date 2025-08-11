import Foundation

extension Date {
    /// Returns a localized short time string for the date.
    func formattedTime(locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = locale
        return formatter.string(from: self)
    }
}
