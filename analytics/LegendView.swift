import SwiftUI

public struct LegendItem: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let color: Color
    public init(name: String, color: Color) {
        self.name = name
        self.color = color
    }
}

public struct ChartLegendView: View {
    public let items: [LegendItem]
    public let columns: Int

    public init(items: [LegendItem], columns: Int = 2) {
        self.items = items
        self.columns = columns
    }

    public var body: some View {
        let grid = Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .leading), count: columns)
        LazyVGrid(columns: grid, alignment: .leading, spacing: 10) {
            ForEach(items) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 6, height: 6)
                    Text(item.name)
                        .font(.footnote)
                        .foregroundStyle(Color("Subtext", bundle: .main))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    {
                        #if canImport(UIKit)
                        return Color(uiColor: .systemBackground)
                        #elseif canImport(AppKit)
                        return Color(nsColor: .windowBackgroundColor)
                        #else
                        return Color.white
                        #endif
                    }()
                )
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 8)
        )
    }
}

