import SwiftUI

// MARK: - Color helpers
extension Color {
    init(hex: String, alpha: Double = 1.0) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hexString.count {
        case 3: (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: alpha)
    }
}

// MARK: - Modern Theme Architecture
public enum AppTheme {
    
    // MARK: - Core Palette
    public enum Colors {
        public static func named(_ name: String, fallback: Color) -> Color {
#if canImport(UIKit)
            if UIColor(named: name) != nil { return Color(name) }
#elseif canImport(AppKit)
            if NSColor(named: name) != nil { return Color(name) }
#endif
            return fallback
        }
        
        // Brand
        public static let brand        = named("BrandColor", fallback: Color(hex: "#7E88FF"))
        public static let brandShade   = named("BrandShade", fallback: brand.opacity(0.85))
        public static let brandHighlight = named("BrandHighlight", fallback: brand)
        
        // Text
        public static let textPrimary   = named("Maintext", fallback: Color.primary)
        public static let textSecondary = named("Subtext", fallback: Color.secondary)
        public static let maintext = named("Maintext", fallback: textPrimary)
        public static let subtext = named("Subtext", fallback: textSecondary)
        
        // Surfaces
        public static let backing        = named("Backing", fallback: Color(uiColor: .secondarySystemBackground))
        public static let shade          = named("Shade", fallback: Color.gray.opacity(0.08))
        public static let highlight      = named("Highlight", fallback: Color.gray.opacity(0.2))
        public static let overlay        = named("Overlay", fallback: Color.black.opacity(0.1))
        public static let module         = named("Module", fallback: Color.black.opacity(0.8))
        
        // Semantic
        public static let success = named("Success", fallback: .green)
        public static let warning = named("Warning", fallback: .yellow)
        public static let error   = named("Error", fallback: .red)
        
        // Graph palette
        public static let graph: [Color] = [
            named("GraphColor1", fallback: Color(hex: "#2ECC71")),
            named("GraphColor2", fallback: Color(hex: "#3498DB")),
            named("GraphColor3", fallback: Color(hex: "#9B59B6")),
            named("GraphColor4", fallback: Color(hex: "#E84393")),
            named("GraphColor5", fallback: Color(hex: "#F1C40F")),
            named("GraphColor6", fallback: Color(hex: "#E67E22")),
            named("GraphColor7", fallback: Color(hex: "#E74C3C")),
            named("GraphColor8", fallback: Color(hex: "#FF6B6B")),
            named("GraphColor9", fallback: Color(hex: "#95A5A6")),
            named("GraphColor10", fallback: Color(hex: "#ECF0F1"))
        ]
    }
    
    // MARK: - Typography
    public enum Typography {
        public static let primary     = Colors.textPrimary
        public static let secondary   = Colors.textSecondary
    }
    
    // MARK: - Surfaces
    public enum Surfaces {
        public static let base        = Colors.backing
        public static let subtle      = Colors.shade
        public static let border      = Colors.highlight
        public static let overlay     = Colors.overlay
        public static let module      = Colors.module
    }
    
    
    
    
    
    
    
    // MARK: - Stacked Card Theme (ANALYTICS CARDS!)
    public enum Sheets {
        public enum Transactions {
            public static let iconTint: Color = Color(hex: "#FFFFFF")
            public static let iconStroke: Color = Color(hex: "#FFFFFF", alpha: 0.15)
            public static let background: Color = Color(hex: "#7E8BFF")
        }
        public enum UAW {
            public static let iconTint: Color = Color(hex: "#3B4491")
            public static let iconStroke: Color = Color(hex: "#3B4491", alpha: 0.15)
            public static let background: Color = Color(hex: "#C5CBFF")
        }
        public enum GasFees {
            public static let iconTint: Color = Color(hex: "#131417")
            public static let iconStroke: Color = Color(hex: "#DCDEE1")
            public static let background: Color = Color(hex: "#EFEFEF")
        }
        public enum TransactionFees {
            public static let iconTint: Color = Color(hex: "#FF4245")
            public static let iconStroke: Color = Color(hex: "#FF4245", alpha: 0.15)
            public static let background: Color = Color(hex: "#FFFFFF")
        }
        
        
    }
    
    // MARK: - Stacked Card Theme (CATEGORIES CARDS!)
    public enum StackedCard {
        public enum CategoriesPerPosition {
            public static func background(for index: Int) -> Color {
                switch index {
                case 0: return Color(hex: "#FFD341")
                case 1: return Color(hex: "#7E8BFF")
                case 2: return Color(hex: "#74B9FF")
                default: return Color(hex: "#FFFFFF")
                }
            }
            public static func iconTint(for index: Int) -> Color {
                switch index {
                case 0: return Color(hex: "#824600")
                case 1: return Color(hex: "#FFFFFF")
                case 2: return Color(hex: "#FFFFFF")
                default: return Color(hex: "#DCDEE1")
                }
            }
            public static func border(for index: Int) -> Color {
                switch index {
                case 0: return Color(hex: "#824600", alpha: 0.15)
                case 1: return Color(hex: "#FFFFFF", alpha: 0.15)
                case 2: return Color(hex: "#FFFFFF", alpha: 0.15)
                default: return Color(hex: "#DCDEE1")
                }
            }
            public static func foreground(for index: Int) -> Color {
                switch index {
                case 0: return Color(hex: "#824600")
                case 1: return Color(hex: "#FFFFFF")
                case 2: return Color(hex: "#FFFFFF")
                default: return Color(hex: "#131417")
                }
            }
        }
        
        public enum CategoriesPerKind {
            public static func background(for kind: CategoryKind) -> Color {
                return AppTheme.Surfaces.base
            }
            public static func iconTint(for kind: CategoryKind) -> Color {
                return AppTheme.Typography.primary
            }
            public static func border(for kind: CategoryKind) -> Color {
                return AppTheme.Surfaces.border
            }
            public static func foreground(for kind: CategoryKind) -> Color {
                return AppTheme.Typography.primary
            }
        }
        
    }
    
}
