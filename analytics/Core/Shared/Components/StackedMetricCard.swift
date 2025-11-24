import SwiftUI

public struct StackedMetricCardStyle {
    public var background: AnyShapeStyle
    public var borderColor: Color?
    public var iconSystemName: String?
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
    
    public init(
        background: some ShapeStyle,
        borderColor: Color? = nil,
        iconSystemName: String? = nil,
        iconImage: Image? = nil,
        iconTint: Color = .white,
        title: String,
        subtitle: String? = nil,
        value: String,
        foreground: Color = .white,
        height: CGFloat = 180,
        cornerRadius: CGFloat = 38,
        shadowColor: Color = Color.black.opacity(0.18),
        shadowRadius: CGFloat = 75,
        shadowY: CGFloat = 15,
        accessoryContent: (() -> AnyView)? = nil
    ) {
        self.background = AnyShapeStyle(background)
        self.borderColor = borderColor
        self.iconSystemName = iconSystemName
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
    }
}

public struct StackedMetricCard: View {
    public let title: String
    public let subtitle: String?
    public let valueText: String
    public let background: AnyShapeStyle
    public let iconSystemName: String?
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
    
    public init(
        title: String,
        subtitle: String? = nil,
        valueText: String,
        background: some ShapeStyle,
        iconSystemName: String? = nil,
        iconImage: Image? = nil,
        iconTint: Color = .white,
        borderColor: Color? = nil,
        foreground: Color = .white,
        height: CGFloat = 180,
        cornerRadius: CGFloat = 38,
        shadowColor: Color = Color.black.opacity(0.18),
        shadowRadius: CGFloat = 75,
        shadowY: CGFloat = 15,
        accessoryContent: (() -> AnyView)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.valueText = valueText
        self.background = AnyShapeStyle(background)
        self.iconSystemName = iconSystemName
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
    }
    
    public init(style: StackedMetricCardStyle) {
        self.title = style.title
        self.subtitle = style.subtitle
        self.valueText = style.value
        self.background = style.background
        self.iconSystemName = style.iconSystemName
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
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top handle
            Rectangle()
                .frame(width: 36, height: 5)
                .foregroundColor(foreground.opacity(0.2))
                .clipShape(Capsule())
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            HStack(spacing: 66) {
                HStack(spacing: 8) {
                    ZStack {
                        if let iconImage = iconImage {
                            iconImage
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(iconTint)
                        } else if let name = iconSystemName {
                            Image(systemName: name)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(iconTint)
                        }
                    }
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.0))
                    )
                    .overlay(
                        Circle()
                            .stroke((borderColor ?? Color.white.opacity(0.15)), lineWidth: 1)
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(foreground.opacity(0.7))
                        }
                        Text(title)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(foreground)
                    }
                    .frame(minWidth: 77, alignment: .leading)
                }
                Spacer()
                Text(valueText)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(foreground)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            
            if let accessoryContent = accessoryContent {
                accessoryContent()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
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
                background: LinearGradient(colors: [Color(red: 0.49, green: 0.55, blue: 1), Color(red: 0.49, green: 0.55, blue: 1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                iconSystemName: "square.grid.2x2.fill",
                iconTint: .white,
                borderColor: Color.white.opacity(0.15),
                foreground: .white,
                height: 180
            )
            .zIndex(1)

            StackedMetricCard(
                title: "UAW",
                subtitle: "Network",
                valueText: "144.3k",
                background: LinearGradient(colors: [Color(red: 0.77, green: 0.80, blue: 1), Color(red: 0.77, green: 0.80, blue: 1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                iconSystemName: "person.3.fill",
                iconTint: Color(red: 0.23, green: 0.27, blue: 0.57),
                borderColor: Color(red: 0.23, green: 0.27, blue: 0.57).opacity(0.15),
                foreground: Color(red: 0.23, green: 0.27, blue: 0.57),
                height: 140
            )
            .offset(y: -45)
            .zIndex(2)

            StackedMetricCard(
                title: "Gas Fees",
                subtitle: "Network",
                valueText: "3.343M",
                background: LinearGradient(colors: [Color(red: 0.94, green: 0.94, blue: 0.94), Color(red: 0.91, green: 0.91, blue: 0.91)], startPoint: .topLeading, endPoint: .bottomTrailing),
                iconSystemName: "flame.fill",
                iconTint: Color(red: 0.41, green: 0.41, blue: 0.41),
                borderColor: Color(red: 0.86, green: 0.87, blue: 0.88),
                foreground: Color(red: 0.18, green: 0.18, blue: 0.18),
                height: 100
            )
            .offset(y: -90)
            .zIndex(3)

            StackedMetricCard(
                title: "Transaction Fees",
                subtitle: "Network",
                valueText: "19,603",
                background: Color.white,
                iconSystemName: "creditcard.fill",
                iconTint: Color(red: 1, green: 0.26, blue: 0.27),
                borderColor: Color(red: 1, green: 0.26, blue: 0.27).opacity(0.15),
                foreground: Color(red: 0.07, green: 0.08, blue: 0.09),
                height: 60
            )
            .offset(y: -135)
            .zIndex(4)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
