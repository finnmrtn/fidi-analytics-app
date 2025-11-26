import SwiftUI

/// Usage:
/// iconTint: AppTheme.Analytics.uawIconTint
/// iconStrokeColor: AppTheme.Analytics.uawStrokeColor
/// background: AppTheme.Categories.primaryBackground

extension Color {
    init(hex: String, alpha: Double = 1.0) {
        var hexString = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hexString.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: alpha)
    }
}

public enum AppTheme {
    
    public static func namedColor(_ name: String, fallback: Color) -> Color {
        // Attempt to load from asset catalog; if not present, return fallback
        #if canImport(UIKit)
        if UIColor(named: name) != nil { return Color(name) }
        #elseif canImport(AppKit)
        if NSColor(named: name) != nil { return Color(name) }
        #else
        // SwiftUI-only environment: attempt anyway
        return Color(name)
        #endif
        return fallback
    }
    
    public static func assetOrHex(_ name: String, hex: String, alpha: Double = 1.0) -> Color {
        return namedColor(name, fallback: Color(hex: hex, alpha: alpha))
    }
    
    public enum Analytics {
        public static let uawIconTint: Color = AppTheme.namedColor("UAWIconColor", fallback: Color(hex: "#3B4A92"))
        public static let uawStrokeColor: Color = AppTheme.namedColor("UAWStrokeColor", fallback: Color(hex: "#3B4A92").opacity(0.15))
        public static let txIconTint: Color = AppTheme.namedColor("TxIconColor", fallback: Color(hex: "#3B4A92"))
        public static let txStrokeColor: Color = AppTheme.namedColor("TxStrokeColor", fallback: Color(hex: "#3B4A92").opacity(0.15))
        public static let gasFeeIconTint: Color = AppTheme.namedColor("GasFeeIconColor", fallback: Color(hex: "#6A6A6A"))
        public static let gasFeeStrokeColor: Color = AppTheme.namedColor("GasFeeStrokeColor", fallback: Color(hex: "#DCDDE0"))
        
        // Net Fee colors (used by TransactionFeeSheet)
        public static let netFeeIconResolved: Color = {
            // Try to use a named color `.netFeeIcon` if defined as an asset alias; otherwise fall back to hex
            // Since `.netFeeIcon` isn't a named asset by default, use a sensible fallback
            return AppTheme.assetOrHex("NetFeeIconColor", hex: "#FF4245")
        }()
        public static let netFeeStrokeResolved: Color = {
            return AppTheme.assetOrHex("NetFeeStrokeColor", hex: "#FF4245").opacity(0.15)
        }()
        
        // Common surfaces
        public static let backing: Color = {
            // Prefer a project-defined Color.backing if present; otherwise use system secondary background
            #if canImport(UIKit)
            return Color(uiColor: .secondarySystemBackground)
            #else
            return Color.gray.opacity(0.08)
            #endif
        }()
        public static let shade: Color = Color.black.opacity(0.06)
    }
    
    public enum Categories {
        public static let primaryIconTint = Color(hex: "#824500")
        public static let primaryBorder = Color(hex: "#824500").opacity(0.15)
        public static let primaryBackground = Color(hex: "#FFD341")
        
        public static let secondaryIconTint = AppTheme.namedColor("TxIconColor", fallback: Color(hex: "#3B4A92"))
        public static let secondaryBorder = AppTheme.namedColor("TxStrokeColor", fallback: Color(hex: "#3B4A92").opacity(0.15))
        public static let secondaryBackground = AppTheme.namedColor("BrandColor", fallback: Color(hex: "#E0E6FF"))
        
        public static let tertiaryForeground = Color(hex: "#2E2E2E")
        public static let tertiaryIconTint = Color(hex: "#74B9FF")
        public static let tertiaryBackgroundLight = Color(hex: "#F4F5F8")
        public static let tertiaryBackgroundDark = Color(hex: "#E8E9EC")
        
        public static let otherForeground = Color(hex: "#121416")
        public static let otherIconTint: Color = {
            // Try to use Color.subtext if provided elsewhere; otherwise fallback to secondary
            return AppTheme.namedColor("SubtextColor", fallback: Color.secondary)
        }()
        public static let otherBorder: Color = {
            return AppTheme.namedColor("HighlightColor", fallback: Color.gray.opacity(0.2))
        }()
        public static let otherBackground = Color.white
    }
    
    public static let textPrimary: Color = .primary
    public static let textSecondary: Color = .secondary
    public static let borderSubtle: Color = Color.gray.opacity(0.2)
}
