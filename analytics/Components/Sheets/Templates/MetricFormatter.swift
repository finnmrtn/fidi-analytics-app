import Foundation

enum MetricFormatter {
    static func abbreviatedCurrency(_ value: Double, currencySymbol: String = "$") -> String {
        let formatted = abbreviated(value)
        return "\(currencySymbol)\(formatted)"
    }

    static func abbreviated(_ value: Double) -> String {
        let absoluteValue = abs(value)
        let sign = value < 0 ? "-" : ""

        switch absoluteValue {
        case 1_000_000_000...:
            return "\(sign)\(String(format: "%.1f", absoluteValue / 1_000_000_000))B"
        case 1_000_000...:
            return "\(sign)\(String(format: "%.1f", absoluteValue / 1_000_000))M"
        case 1_000...:
            return "\(sign)\(String(format: "%.1f", absoluteValue / 1_000))K"
        default:
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            numberFormatter.maximumFractionDigits = 0
            let fallback = numberFormatter.string(from: NSNumber(value: absoluteValue)) ?? String(format: "%.0f", absoluteValue)
            return "\(sign)\(fallback)"
        }
    }
}
