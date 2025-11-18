import Foundation

public enum NumberAbbrev {
    public static func abbreviate(_ value: Double, currencyCode: String? = "USD") -> String {
        let absVal = abs(value)
        let sign = value < 0 ? "-" : ""
        let formatted: String
        switch absVal {
        case 1_000_000_000...:
            formatted = String(format: "%.1fB", absVal / 1_000_000_000)
        case 1_000_000...:
            formatted = String(format: "%.1fM", absVal / 1_000_000)
        case 1_000...:
            formatted = String(format: "%.1fk", absVal / 1_000)
        default:
            formatted = String(format: "%.0f", absVal)
        }
        if let currencyCode = currencyCode {
            let symbol = currencySymbol(for: currencyCode)
            return sign + symbol + formatted
        } else {
            return sign + formatted
        }
    }
    
    private static func currencySymbol(for code: String) -> String {
        let localeIds = Locale.availableIdentifiers
        for localeId in localeIds {
            let locale = Locale(identifier: localeId)
            if locale.currencyCode == code {
                if let symbol = locale.currencySymbol {
                    return symbol
                }
            }
        }
        return "$"
    }
}
