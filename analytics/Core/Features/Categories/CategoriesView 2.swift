import SwiftUI
import Charts

struct CategoryItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let metric1Title: String
    let metric1Value: String
    let metric2Title: String
    let metric2Value: String
    let value: Double // For pie chart segment size
}

struct CategoriesView: View {
    private let categories: [CategoryItem] = [
        CategoryItem(
            title: "DeFi",
            icon: "dollarsign.circle.fill",
            color: Color(hex: "#FFB800"),
            metric1Title: "TVL",
            metric1Value: "$32.5B",
            metric2Title: "Users",
            metric2Value: "1.2M",
            value: 45
        ),
        CategoryItem(
            title: "Gaming",
            icon: "gamecontroller.fill",
            color: Color(hex: "#5A4BDA"),
            metric1Title: "Active",
            metric1Value: "85K",
            metric2Title: "Revenue",
            metric2Value: "$4.1M",
            value: 25
        ),
        CategoryItem(
            title: "Infrastructure",
            icon: "server.rack",
            color: Color(hex: "#D6D7E2"),
            metric1Title: "Nodes",
            metric1Value: "7.4K",
            metric2Title: "Uptime",
            metric2Value: "99.8%",
            value: 20
        ),
        CategoryItem(
            title: "Other",
            icon: "ellipsis.circle.fill",
            color: Color.white,
            metric1Title: "Projects",
            metric1Value: "112",
            metric2Title: "Change",
            metric2Value: "+3.4%",
            value: 10
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    topMetricCard
                    categoryCards
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .padding(.top, 12)
                .frame(maxWidth: .infinity)
            }
            .background(Color("Background").ignoresSafeArea())
            .navigationTitle("Categories")
        }
    }

    private var topMetricCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color("Background"))
                        .opacity(0)
                }

            VStack(spacing: 20) {
                Text("Categories Overview")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)

                Chart {
                    ForEach(categories) { item in
                        SectorMark(
                            angle: .value("Value", item.value),
                            innerRadius: .ratio(0.65),
                            angularInset: 1.0
                        )
                        .foregroundStyle(item.color)
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 180)
            }
            .padding(24)
        }
        .padding(.horizontal, 4)
    }

    private var categoryCards: some View {
        VStack(spacing: 16) {
            ForEach(categories) { category in
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(category.color)
                        Image(systemName: category.icon)
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(category.color.isLight ? .black : .white)
                    }
                    .frame(width: 56, height: 56)

                    Text(category.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(category.metric1Title)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text(category.metric1Value)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(category.color)
                    }
                    .frame(minWidth: 70)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(category.metric2Title)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text(category.metric2Value)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(category.color)
                    }
                    .frame(minWidth: 70)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(category.color.opacity(category.color.isLight ? 0.15 : 0.25))
                )
            }
        }
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Returns true if color is relatively light, used to pick contrasting foreground.
    var isLight: Bool {
        // Convert to UIColor to get brightness component
        #if canImport(UIKit)
        var white: CGFloat = 0
        UIColor(self).getWhite(&white, alpha: nil)
        return white > 0.7
        #else
        return false
        #endif
    }
}

#Preview {
    CategoriesView()
        .preferredColorScheme(.light)
        .environment(\.colorSchemeContrast, .standard)
}
