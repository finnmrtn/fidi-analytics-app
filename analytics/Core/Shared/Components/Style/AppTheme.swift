import SwiftUI

// MARK: - Color helpers
extension Color {
    init(hex: String, alpha: Double = 1.0) {
        var hexString = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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

// MARK: - Theme root
public enum AppTheme {

    // Prefer named asset, fallback to provided color
    public static func namedColor(_ name: String, fallback: Color) -> Color {
        #if canImport(UIKit)
        if UIColor(named: name) != nil { return Color(name) }
        #elseif canImport(AppKit)
        if NSColor(named: name) != nil { return Color(name) }
        #else
        return Color(name)
        #endif
        return fallback
    }

    // MARK: Palette (raw assets)
    public enum Palette {
        public static let brand = AppTheme.namedColor("BrandColor", fallback: Color(hex: "#7E88FF"))
        public static let brandHighlight = AppTheme.namedColor("BrandHighlight", fallback: brand)
        public static let brandShade = AppTheme.namedColor("BrandShade", fallback: brand.opacity(0.85))

        public static let mainText = AppTheme.namedColor("Maintext", fallback: Color.primary)
        public static let subText = AppTheme.namedColor("Subtext", fallback: Color.secondary)

        public static let backing = AppTheme.namedColor("Backing", fallback: Color(uiColor: .secondarySystemBackground))
        public static let shade = AppTheme.namedColor("Shade", fallback: Color.gray.opacity(0.08))
        public static let highlight = AppTheme.namedColor("Highlight", fallback: Color.gray.opacity(0.2))
        public static let overlay = AppTheme.namedColor("Overlay", fallback: Color.black.opacity(0.1))
        public static let module = AppTheme.namedColor("Module", fallback: Color.black.opacity(0.8))

        public static let success = AppTheme.namedColor("Success", fallback: Color.green)
        public static let warning = AppTheme.namedColor("Warning", fallback: Color.yellow)
        public static let error = AppTheme.namedColor("Error", fallback: Color.red)

        // Graph palette (1..10)
        public static let graph1 = AppTheme.namedColor("GraphColor1", fallback: Color(hex: "#2ECC71"))
        public static let graph2 = AppTheme.namedColor("GraphColor2", fallback: Color(hex: "#3498DB"))
        public static let graph3 = AppTheme.namedColor("GraphColor3", fallback: Color(hex: "#9B59B6"))
        public static let graph4 = AppTheme.namedColor("GraphColor4", fallback: Color(hex: "#E84393"))
        public static let graph5 = AppTheme.namedColor("GraphColor5", fallback: Color(hex: "#F1C40F"))
        public static let graph6 = AppTheme.namedColor("GraphColor6", fallback: Color(hex: "#E67E22"))
        public static let graph7 = AppTheme.namedColor("GraphColor7", fallback: Color(hex: "#E74C3C"))
        public static let graph8 = AppTheme.namedColor("GraphColor8", fallback: Color(hex: "#FF6B6B"))
        public static let graph9 = AppTheme.namedColor("GraphColor9", fallback: Color(hex: "#95A5A6"))
        public static let graph10 = AppTheme.namedColor("GraphColor10", fallback: Color(hex: "#ECF0F1"))
    }

    // MARK: Text
    public enum Text {
        public static let primary: Color = Palette.mainText
        public static let secondary: Color = Palette.subText
    }

    // MARK: Surfaces
    public enum Surfaces {
        public static let backing: Color = Palette.backing
        public static let shade: Color = Palette.shade
        public static let highlight: Color = Palette.highlight
        public static let overlay: Color = Palette.overlay
        public static let module: Color = Palette.module
        public static let cardBorderSubtle: Color = Palette.highlight // generic subtle border
    }

    // MARK: Analytics (shared)
    public enum Analytics {
        public static let uawIconTint: Color = AppTheme.namedColor("UAWIconColor", fallback: Palette.brand)
        public static let uawStrokeColor: Color = AppTheme.namedColor("UAWStrokeColor", fallback: Palette.brand.opacity(0.15))
        public static let txIconTint: Color = AppTheme.namedColor("TxIconColor", fallback: Palette.brand)
        public static let txStrokeColor: Color = AppTheme.namedColor("TxStrokeColor", fallback: Palette.brand.opacity(0.15))
        public static let gasFeeIconTint: Color = AppTheme.namedColor("GasFeeIconColor", fallback: Palette.subText)
        public static let gasFeeStrokeColor: Color = AppTheme.namedColor("GasFeeStrokeColor", fallback: Palette.highlight)

        public static let netFeeIconResolved: Color = AppTheme.namedColor("NetFeeIconColor", fallback: Color(hex: "#FF4245"))
        public static let netFeeStrokeResolved: Color = AppTheme.namedColor("NetFeeStrokeColor", fallback: Color(hex: "#FF4245").opacity(0.15))

        public static let backing: Color = Surfaces.backing
        public static let shade: Color = Surfaces.shade
    }

    // MARK: Categories (shared)
    public enum Categories {
        public static let primaryIconTint = Color(hex: "#824500")
        public static let primaryBorder = Color(hex: "#824500").opacity(0.15)
        public static let primaryBackground = Color(hex: "#FFD341")

        public static let secondaryIconTint = Palette.brand
        public static let secondaryBorder = Palette.brand.opacity(0.15)
        public static let secondaryBackground = Palette.brandShade

        public static let tertiaryForeground = Palette.mainText
        public static let tertiaryIconTint = Color(hex: "#74B9FF")
        public static let tertiaryBackgroundLight = Color(hex: "#F4F5F8")
        public static let tertiaryBackgroundDark = Color(hex: "#E8E9EC")

        public static let otherForeground = Palette.mainText
        public static let otherIconTint = Palette.subText
        public static let otherBorder = Palette.highlight
        public static let otherBackground = Color.white
    }

    // MARK: Public shorthands
    public static let textPrimary: Color = Text.primary
    public static let textSecondary: Color = Text.secondary
    public static let borderSubtle: Color = Surfaces.cardBorderSubtle


    // MARK: - Sheets
    // MARK: Sheets (header/title theming distinct from stacked cards)
    public enum Sheets {
        // Standard
        public enum Standard {
            public static let iconTint: Color = Color(hex: "#696969")
            public static let iconStroke: Color = Color(hex: "#DCDEE1")
            public static let titleText: Color = Color(hex: "#2F2F2F")
            public static let totalsIconTint: Color = Color(hex: "#2F2F2F")
            public static let totalsTextTint: Color = Color(hex: "#2F2F2F")
            public static let closeButtonTint: Color = Color(hex: "#696969")
            public static let background: Color = Color(hex: "#FFFFFF")
        }
        // Categories
        public enum Categories {
            public static let iconTint: Color = Color(hex: "#7E88FF")
            public static let iconStroke: Color = Color(hex: "#7E88FF", alpha: 0.15)
            public static let titleText: Color = Color(hex: "#2F2F2F")
            public static let totalsIconTint: Color = Color(hex: "#696969")
            public static let totalsTextTint: Color = Color(hex: "#696969")
            public static let closeButtonTint: Color = Color(hex: "#2F2F2F")
            public static let background: Color = Color(hex: "#7E88FF", alpha: 0.85)
        }

        // Analytics: Transactions
        public enum Transactions {
            public static let iconTint: Color = Color(hex: "#7E8BFF")
            public static let iconStroke: Color = Color(hex: "#7E8BFF", alpha: 0.15)
            public static let titleText: Color = Color(hex: "#2F2F2F")
            public static let totalsIconTint: Color = Color(hex: "#2F2F2F")
            public static let totalsTextTint: Color = Color(hex: "#2F2F2F")
            public static let closeButtonTint: Color = Color(hex: "#7E8BFF")
            public static let background: Color = Color(hex: "#FFFFFF")
        }

        // Analytics: UAW
        public enum UAW {
            public static let iconTint: Color = Color(hex: "#3B4491")
            public static let iconStroke: Color = Color(hex: "#3B4491", alpha: 0.15)
            public static let titleText: Color = Color(hex: "#3B4491")
            public static let totalsIconTint: Color = Color(hex: "#3B4491")
            public static let totalsTextTint: Color = Color(hex: "#3B4491")
            public static let closeButtonTint: Color = Color(hex: "#3B4491")
            public static let background: Color = Color(hex: "#FFFFFF")
        }

        // Analytics: Gas Fees
        public enum GasFees {
            public static let iconTint: Color = Color(hex: "#696969")
            public static let iconStroke: Color = Color(hex: "#DCDEE1")
            public static let titleText: Color = Color(hex: "#2F2F2F")
            public static let totalsIconTint: Color = Color(hex: "#2F2F2F")
            public static let totalsTextTint: Color = Color(hex: "#2F2F2F")
            public static let closeButtonTint: Color = Color(hex: "#2F2F2F")
            public static let background: Color = Color(hex: "#FFFFFF")
        }

        // Analytics: Transaction Fees
        public enum TransactionFees {
            public static let iconTint: Color = Color(hex: "#FF4245")
            public static let iconStroke: Color = Color(hex: "#FF4245", alpha: 0.15)
            public static let titleText: Color = Color(hex: "#2F2F2F")
            public static let totalsIconTint: Color = Color(hex: "#696969")
            public static let totalsTextTint: Color = Color(hex: "#696969")
            public static let closeButtonTint: Color = Color(hex: "#2F2F2F")
            public static let background: Color = Color(hex: "#FFFFFF")
        }

        // Categories Per Position
        public enum CategoriesPerPosition {
            public static func iconTint(for position: Int) -> Color {
                switch position {
                case 0: return Color(hex: "#824600")        // Card0.iconTint
                case 1: return Color(hex: "#FFFFFF")        // Card1.iconTint (brand)
                case 2: return Color(hex: "#FFFFFF")        // Card2.iconTint
                default: return Color(hex: "#696969")       // Card3.iconTint (subText fallback)
                }
            }
            public static func iconStroke(for position: Int) -> Color {
                switch position {
                case 0: return Color(hex: "#824600", alpha: 0.15)   // Card0.border
                case 1: return Color(hex: "#FFFFFF", alpha: 0.15)   // Card1.border
                case 2: return Color(hex: "#FFFFFF", alpha: 0.15)    // Card2.border
                default: return Color(hex: "#DCDEE1")               // Card3.border
                }
            }

            public static func titleText(for position: Int) -> Color {
                switch position {
                case 0: return Color(hex: "#824500")        // Card0.foreground
                case 1: return Color(hex: "#FFFFFF")        // Card1.foreground
                case 2: return Color(hex: "#2F2F2F")        // Card2.foreground
                default: return Color(hex: "#2F2F2F")       // Card3.foreground
                }
            }

            public static func totalsTextTint(for position: Int) -> Color {
                switch position {
                case 0: return Color(hex: "#824500")
                case 1: return Color(hex: "#FFFFFF")
                case 2: return Color(hex: "#2F2F2F")
                default: return Color(hex: "#2F2F2F")
                }
            }

            public static func closeButtonTint(for position: Int) -> Color {
                switch position {
                case 0: return Color(hex: "#824500")
                case 1: return Color(hex: "#FFFFFF")
                case 2: return Color(hex: "#696969")
                default: return Color(hex: "#2F2F2F")
                }
            }

            public static let titleText: Color = AppTheme.Text.primary
            public static let totalsIconTint: Color = AppTheme.Text.secondary
            public static let totalsTextTint: Color = AppTheme.Text.secondary
            public static let closeButtonTint: Color = AppTheme.Text.primary
        }

        // Analytics Per Position
        public enum AnalyticsPerPosition {
            // Position mapping:
            // 0: Transactions, 1: UAW, 2: Gas Fees, 3+: Transaction Fees
            public static func iconTint(for position: Int) -> Color {
                switch position {
                case 0: return Color(hex: "#FFFFFF")      // Analytics.Card0.iconTint
                case 1: return Color(hex: "#3B4491")      // Analytics.Card1.iconTint
                case 2: return Color(hex: "#696969")      // Analytics.Card2.iconTint
                default: return Color(hex: "#FF4245")     // Analytics.Card3.iconTint
                }
            }

            public static func iconStroke(for position: Int) -> Color {
                switch position {
                case 0: return Color(hex: "#FFFFFF", alpha: 0.15) // Analytics.Card0.border
                case 1: return Color(hex: "#3B4491", alpha: 0.15) // Analytics.Card1.border
                case 2: return Color(hex: "#DCDEE1")              // Analytics.Card2.border
                default: return Color(hex: "#FF4245", alpha: 0.15) // Analytics.Card3.border
                }
            }

            public static func titleText(for position: Int) -> Color {
                switch position {
                case 0: return Color(hex: "#FFFFFF")      // Analytics.Card0.foreground
                case 1: return Color(hex: "#3B4491")      // Analytics.Card1.foreground
                case 2: return Color(hex: "#2F2F2F")      // Analytics.Card2.foreground
                default: return Color(hex: "#2F2F2F")     // Analytics.Card3.foreground
                }
            }

            public static func totalsTextTint(for position: Int) -> Color {
                switch position {
                case 0: return Color(hex: "#FFFFFF")
                case 1: return Color(hex: "#3B4491")
                case 2: return Color(hex: "#2F2F2F")
                default: return Color(hex: "#2F2F2F")
                }
            }

            public static func closeButtonTint(for position: Int) -> Color {
                switch position {
                case 0: return Color(hex: "#FFFFFF")
                case 1: return Color(hex: "#3B4491")
                case 2: return Color(hex: "#2F2F2F")
                default: return Color(hex: "#2F2F2F")
                }
            }
        }
    }

    // MARK: Stacked Cards presets
    // MARK: Stacked Cards presets
    public enum StackedCards {

        // MARK: Analytics Cards
        public enum Analytics {

            public struct Card0 { // Transactions
                public static let iconTint = Color(hex: "#FFFFFF")            // brand
                public static let border = Color(hex: "#FFFFFF", alpha: 0.15) // brand @ 15%
                public static let foreground = Color(hex: "#FFFFFF")          // mainText fallback
                public static let background = Color(hex: "#7E88FF") // brandShade
            }

            public struct Card1 { // UAW
                public static let iconTint = Color(hex: "#3B4491")            // brand
                public static let border = Color(hex: "#3B4491", alpha: 0.15)
                public static let foreground = Color(hex: "#3B4491")
                public static let background = Color(hex: "#C5CBFF")          // fallback shade
            }

            public struct Card2 { // Gas Fees
                public static let iconTint = Color(hex: "#696969")            // subText fallback
                public static let border = Color(hex: "#DCDEE1")              // highlight fallback
                public static let foreground = Color(hex: "#2F2F2F")
                public static let background = Color(hex: "#EFEFEF") // shade fallback
            }

            public struct Card3 { // Transaction Fees
                public static let iconTint = Color(hex: "#FF4245")            // netFeeIconResolved
                public static let border = Color(hex: "#FF4245", alpha: 0.15) // netFeeStrokeResolved
                public static let foreground = Color(hex: "#2F2F2F")
                public static let background = Color.white
            }
        }

        // MARK: Category Cards
        public enum Categories {

            public struct Card0 { // Top Category (DeFi)
                public static let iconTint = Color(hex: "#824500")
                public static let border = Color(hex: "#824500", alpha: 0.15)
                public static let foreground = Color(hex: "#824500")
                public static let background = Color(hex: "#FFD341")
            }

            public struct Card1 { // Second Category (Gaming)
                public static let iconTint = Color(hex: "#7E88FF")            // brand
                public static let border = Color(hex: "#7E88FF", alpha: 0.15)
                public static let foreground = Color.white
                public static let background = Color(hex: "#7E88FF", alpha: 0.85) // brandShade
            }

            public struct Card2 { // Third Category (Infrastructure)
                public static let iconTint = Color(hex: "#74B9FF")
                public static let border = Color(hex: "#74B9FF", alpha: 0.15)
                public static let foreground = Color(hex: "#000000")
                public static let background = Color(hex: "#F4F5F8")
            }

            public struct Card3 { // Other
                public static let iconTint = Color(hex: "#8E8E93")            // subText fallback
                public static let border = Color(hex: "#CCCCCC")              // highlight fallback
                public static let foreground = Color(hex: "#000000")
                public static let background = Color.white
            }
        }
    }
}

