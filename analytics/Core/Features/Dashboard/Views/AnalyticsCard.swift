import SwiftUI

struct RectCorner: OptionSet {
    let rawValue: Int

    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let topLeftRadius = corners.contains(.topLeft) ? radius : 0
        let topRightRadius = corners.contains(.topRight) ? radius : 0
        let bottomLeftRadius = corners.contains(.bottomLeft) ? radius : 0
        let bottomRightRadius = corners.contains(.bottomRight) ? radius : 0

        path.move(to: CGPoint(x: rect.minX + topLeftRadius, y: rect.minY))

        // Top edge and top-right corner
        path.addLine(to: CGPoint(x: rect.maxX - topRightRadius, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - topRightRadius, y: rect.minY + topRightRadius),
                    radius: topRightRadius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(0),
                    clockwise: false)

        // Right edge and bottom-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRightRadius))
        path.addArc(center: CGPoint(x: rect.maxX - bottomRightRadius, y: rect.maxY - bottomRightRadius),
                    radius: bottomRightRadius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false)

        // Bottom edge and bottom-left corner
        path.addLine(to: CGPoint(x: rect.minX + bottomLeftRadius, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bottomLeftRadius, y: rect.maxY - bottomLeftRadius),
                    radius: bottomLeftRadius,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false)

        // Left edge and top-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeftRadius))
        path.addArc(center: CGPoint(x: rect.minX + topLeftRadius, y: rect.minY + topLeftRadius),
                    radius: topLeftRadius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)

        path.closeSubpath()
        return path
    }
}

struct AnalyticsCard: View {
    let iconName: String
    let title: String
    let value: String
    let background: LinearGradient
    let iconTint: Color
    let height: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Network")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Text(value)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)
                }

                Spacer(minLength: 0) // hält die Inhalte oben
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .frame(height: height)
            .background(background)
            .clipShape(RoundedCorner(radius: 38, corners: [.topLeft, .topRight]))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct AnalyticsCardStack: View {
    let cards: [AnalyticsCardData]
    let overlap: CGFloat = 32

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(cards.indices, id: \.self) { index in
                let card = cards[index]
                AnalyticsCard(
                    iconName: card.iconName,
                    title: card.title,
                    value: card.value,
                    background: card.background,
                    iconTint: card.iconTint,
                    height: card.height,
                    onTap: card.onTap
                )
                .offset(y: CGFloat(index) * overlap)
                .zIndex(Double(cards.count - index))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

struct AnalyticsCardData {
    let iconName: String
    let title: String
    let value: String
    let background: LinearGradient
    let iconTint: Color
    let height: CGFloat
    let onTap: () -> Void
}
