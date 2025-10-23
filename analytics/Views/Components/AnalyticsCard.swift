import SwiftUI

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
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
