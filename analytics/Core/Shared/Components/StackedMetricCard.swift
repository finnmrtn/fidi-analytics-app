import SwiftUI

public struct StackedMetricCardStyle {
    public var background: AnyShapeStyle
    public var borderColor: Color?
    public var iconImage: Image?
    public var iconTint: Color
    public var title: String
    public var subtitle: String?
    public var value: String
    public var foreground: Color
    public var height: CGFloat
    public var cornerRadius: CGFloat
    public var shadowColor: Color
    public var shadowRadius: CGFloat
    public var shadowY: CGFloat
    public var accessoryContent: (() -> AnyView)?
    public var showsHandle: Bool
    
    public init(
        background: some ShapeStyle,
        borderColor: Color? = nil,
        iconImage: Image? = nil,
        iconTint: Color = AppTheme.textPrimary,
        title: String,
        subtitle: String? = nil,
        value: String,
        foreground: Color = AppTheme.textPrimary,
        height: CGFloat = 180,
        cornerRadius: CGFloat = 38,
        shadowColor: Color = Color.black.opacity(0.18),
        shadowRadius: CGFloat = 75,
        shadowY: CGFloat = 15,
        accessoryContent: (() -> AnyView)? = nil,
        showsHandle: Bool = false
    ) {
        self.background = AnyShapeStyle(background)
        self.borderColor = borderColor
        self.iconImage = iconImage
        self.iconTint = iconTint
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.foreground = foreground
        self.height = height
        self.cornerRadius = cornerRadius
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowY = shadowY
        self.accessoryContent = accessoryContent
        self.showsHandle = showsHandle
    }
}

public struct StackedMetricCard: View {
    public let title: String
    public let subtitle: String?
    public let valueText: String
    public let primaryValueIcon: Image?
    public let primaryValueText: String?
    public let secondaryValueIcon: Image?
    public let secondaryValueText: String?
    public let background: AnyShapeStyle
    public let iconImage: Image?
    public let iconTint: Color
    public let borderColor: Color?
    public let foreground: Color
    public let height: CGFloat
    public let cornerRadius: CGFloat
    public let shadowColor: Color
    public let shadowRadius: CGFloat
    public let shadowY: CGFloat
    public let accessoryContent: (() -> AnyView)?
    public let showsHandle: Bool
    
    public init(
        title: String,
        subtitle: String? = nil,
        valueText: String,
        primaryValueIcon: Image? = nil,
        primaryValueText: String? = nil,
        secondaryValueIcon: Image? = nil,
        secondaryValueText: String? = nil,
        background: some ShapeStyle,
        iconImage: Image? = nil,
        iconTint: Color = AppTheme.textPrimary,
        borderColor: Color? = nil,
        foreground: Color = AppTheme.textPrimary,
        height: CGFloat = 180,
        cornerRadius: CGFloat = 38,
        shadowColor: Color = Color.black.opacity(0.18),
        shadowRadius: CGFloat = 75,
        shadowY: CGFloat = 15,
        accessoryContent: (() -> AnyView)? = nil,
        showsHandle: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.valueText = valueText
        self.primaryValueIcon = primaryValueIcon
        self.primaryValueText = primaryValueText
        self.secondaryValueIcon = secondaryValueIcon
        self.secondaryValueText = secondaryValueText
        self.background = AnyShapeStyle(background)
        self.iconImage = iconImage
        self.iconTint = iconTint
        self.borderColor = borderColor
        self.foreground = foreground
        self.height = height
        self.cornerRadius = cornerRadius
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowY = shadowY
        self.accessoryContent = accessoryContent
        self.showsHandle = showsHandle
    }
    
    public init(style: StackedMetricCardStyle) {
        self.title = style.title
        self.subtitle = style.subtitle
        self.valueText = style.value
        self.primaryValueIcon = nil
        self.primaryValueText = nil
        self.secondaryValueIcon = nil
        self.secondaryValueText = nil
        self.background = style.background
        self.iconImage = style.iconImage
        self.iconTint = style.iconTint
        self.borderColor = style.borderColor
        self.foreground = style.foreground
        self.height = style.height
        self.cornerRadius = style.cornerRadius
        self.shadowColor = style.shadowColor
        self.shadowRadius = style.shadowRadius
        self.shadowY = style.shadowY
        self.accessoryContent = style.accessoryContent
        self.showsHandle = style.showsHandle
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if showsHandle {
                Rectangle()
                    .frame(width: 36, height: 1)
                    .foregroundColor(foreground.opacity(0.2))
                    .clipShape(Capsule())
                    .padding(.top, 8)
                    .padding(.bottom, 12)
            }
            
            HStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center, spacing: 8) {
                    ZStack {
                        if let iconImage = iconImage {
                            iconImage
                                .resizable()
                                .renderingMode(.template)
                                .foregroundStyle(iconTint)
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                    }
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.0))
                    )
                    .overlay(
                        Circle()
                            .stroke((borderColor ?? AppTheme.borderSubtle), lineWidth: 2)
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(foreground.opacity(0.7))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        Text(title)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(foreground)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(minWidth: 80, alignment: .leading)
                }
                Spacer()
                Group {
                    if primaryValueIcon != nil || primaryValueText != nil || secondaryValueIcon != nil || secondaryValueText != nil {
                        if (primaryValueIcon != nil || primaryValueText != nil) && (secondaryValueIcon != nil || secondaryValueText != nil) {
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                HStack(spacing: 6) {
                                    if let icon = primaryValueIcon { icon.resizable().renderingMode(.template).foregroundColor(foreground).frame(width: 18, height: 18) }
                                    Text(primaryValueText ?? "")
                                        .font(.system(size: 20, weight: .semibold))
                                        .monospacedDigit()
                                        .foregroundColor(foreground)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                HStack(spacing: 6) {
                                    if let icon = secondaryValueIcon { icon.resizable().renderingMode(.template).foregroundColor(foreground).frame(width: 18, height: 18) }
                                    Text(secondaryValueText ?? "")
                                        .font(.system(size: 20, weight: .semibold))
                                        .monospacedDigit()
                                        .foregroundColor(foreground.opacity(0.95))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                        } else {
                            // If only one value is provided, show it alone (primary preferred)
                            HStack(spacing: 6) {
                                if let icon = (primaryValueIcon ?? secondaryValueIcon) { icon.resizable().renderingMode(.template).foregroundColor(foreground).frame(width: 18, height: 18) }
                                Text((primaryValueText ?? secondaryValueText) ?? "")
                                    .font(.system(size: 20, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundColor(foreground)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                    } else {
                        Text(valueText)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(foreground)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
            .padding(.horizontal, 16)
            Spacer()
            
            if let accessoryContent = accessoryContent {
                accessoryContent()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
    }
}

public func formatCompactNumber(_ value: Double) -> String {
    guard value.isFinite else { return "—" }
    let absValue = abs(value)
    if absValue >= 1_000_000 {
        let scaled = value / 1_000_000
        return scaled.formatted(.number.precision(.fractionLength(0...1))) + "M"
    } else if absValue >= 1_000 {
        let scaled = value / 1_000
        return scaled.formatted(.number.precision(.fractionLength(0...1))) + "k"
    } else {
        return value.formatted(.number.precision(.fractionLength(0)))
    }
}

#Preview {
    ZStack {
        VStack(spacing: 0) {
            StackedMetricCard(
                title: "Transactions",
                subtitle: "Network",
                valueText: "3.343M",
                background: AppTheme.StackedCards.Analytics.Card0.background,
                iconImage: Image("txn"),
                iconTint: AppTheme.StackedCards.Analytics.Card0.iconTint,
                borderColor: AppTheme.StackedCards.Analytics.Card0.border,
                foreground: AppTheme.StackedCards.Analytics.Card0.foreground,
                height: 180,
                showsHandle: false
            )
            .zIndex(1)

            StackedMetricCard(
                title: "UAW",
                subtitle: "Network",
                valueText: "144.3k",
                background: AppTheme.StackedCards.Analytics.Card1.background,
                iconImage: Image("uaw"),
                iconTint: AppTheme.StackedCards.Analytics.Card1.iconTint,
                borderColor: AppTheme.StackedCards.Analytics.Card1.border,
                foreground: AppTheme.StackedCards.Analytics.Card1.foreground,
                height: 140,
                showsHandle: false
            )
            .offset(y: -45)
            .zIndex(2)

            StackedMetricCard(
                title: "Gas Fees",
                subtitle: "Network",
                valueText: "3.343M",
                background: AppTheme.StackedCards.Analytics.Card2.background,
                iconImage: Image("gasfee"),
                iconTint: AppTheme.StackedCards.Analytics.Card2.iconTint,
                borderColor: AppTheme.StackedCards.Analytics.Card2.border,
                foreground: AppTheme.StackedCards.Analytics.Card2.foreground,
                height: 100,
                showsHandle: false
            )
            .offset(y: -90)
            .zIndex(3)

            StackedMetricCard(
                title: "Transaction Fees",
                subtitle: "Network",
                valueText: "19,603",
                background: AppTheme.StackedCards.Analytics.Card3.background,
                iconImage: Image("networkfee"),
                iconTint: AppTheme.StackedCards.Analytics.Card3.iconTint,
                borderColor: AppTheme.StackedCards.Analytics.Card3.border,
                foreground: AppTheme.StackedCards.Analytics.Card3.foreground,
                height: 80,
                showsHandle: false
            )
            .offset(y: -135)
            .zIndex(4)
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .bottom)
        .padding(.horizontal)
    }
}
