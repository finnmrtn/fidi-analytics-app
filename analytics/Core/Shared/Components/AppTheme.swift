import SwiftUI

public enum SheetVariant {
    case analytics
    case categories
}

public enum CardPosition: Int {
    case one = 0, two = 1, three = 2, four = 3 // four = Other
}

public struct CardTints {
    public let titleColor: Color
    public let iconColorTint: Color
    public let strokeColorTint: Color

    public static func forCardIndex(_ cardIndex: Int) -> CardTints {
        switch cardIndex {
        case 0: // Card 1
            let base = Color(hex: "#824600")
            return CardTints(
                titleColor: base,
                iconColorTint: base,
                strokeColorTint: base.opacity(0.15)
            )
        case 1, 2: // Card 2 & 3
            let base = Color(hex: "#EFEFEF")
            return CardTints(
                titleColor: base,
                iconColorTint: base,
                strokeColorTint: base.opacity(0.15)
            )
        case 3: // Card 4 (Other)
            return CardTints(
                titleColor: .primary,      // Maintext
                iconColorTint: .secondary, // Subtext
                strokeColorTint: .accentColor // Highlight
            )
        default:
            return CardTints(
                titleColor: .primary,
                iconColorTint: .secondary,
                strokeColorTint: .accentColor
            )
        }
    }

    public static func forPosition(_ position: CardPosition) -> CardTints {
        forCardIndex(position.rawValue)
    }
}

public struct SheetHeaderTints {
    public let titleText: Color
    public let iconTint: Color
    public let iconStroke: Color
    public let totalsIconTint: Color
    public let totalsTextTint: Color
    public let closeButtonTint: Color
}

public struct StackAndSheetTheme {
    public init() {}

    public func cardTints(for position: CardPosition) -> CardTints {
        CardTints.forPosition(position)
    }

    public func sheetHeaderTints(for position: CardPosition, variant: SheetVariant) -> SheetHeaderTints {
        // Currently same mapping for both variants. Split here if needed later.
        let card = CardTints.forPosition(position)
        switch position {
        case .one:
            return SheetHeaderTints(
                titleText: card.titleColor,
                iconTint: card.iconColorTint,
                iconStroke: card.strokeColorTint,
                totalsIconTint: card.iconColorTint,
                totalsTextTint: card.titleColor,
                closeButtonTint: card.titleColor
            )
        case .two, .three:
            return SheetHeaderTints(
                titleText: card.titleColor,
                iconTint: card.iconColorTint,
                iconStroke: card.strokeColorTint,
                totalsIconTint: card.iconColorTint,
                totalsTextTint: card.titleColor,
                closeButtonTint: card.titleColor
            )
        case .four:
            return SheetHeaderTints(
                titleText: .primary,            // Maintext
                iconTint: .secondary,           // Subtext
                iconStroke: .accentColor,       // Highlight
                totalsIconTint: .secondary,
                totalsTextTint: .primary,
                closeButtonTint: .primary
            )
        }
    }
}
