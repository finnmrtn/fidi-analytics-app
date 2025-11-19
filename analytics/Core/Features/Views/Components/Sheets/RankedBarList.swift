import SwiftUI

public struct RankedBarItem: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let value: Double
    public let color: Color

    public init(id: String, name: String, value: Double, color: Color) {
        self.id = id
        self.name = name
        self.value = value
        self.color = color
    }
}

public struct RankedBarList: View {
    public let items: [RankedBarItem]

    public init(items: [RankedBarItem]) {
        self.items = items
    }

    private var maxValue: Double {
        items.map { $0.value }.max() ?? 0
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(items) { item in
                RankedBarRow(item: item, maxValue: maxValue)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct RankedBarRow: View {
    let item: RankedBarItem
    let maxValue: Double

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                Text(item.value.formatted())
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                let width = proxy.size.width
                let ratio = maxValue > 0 ? CGFloat(item.value / maxValue) : 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.12))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.color)
                        .frame(width: width * ratio)
                }
            }
            .frame(height: 14)
        }
        .accessibilityLabel("\(item.name), \(item.value)")
    }
}

#Preview("RankedBarList") {
    let demo: [RankedBarItem] = [
        .init(id: "1", name: "App A", value: 1234, color: .blue),
        .init(id: "2", name: "App B", value: 987, color: .green),
        .init(id: "3", name: "App C", value: 456, color: .orange)
    ]
    VStack {
        RankedBarList(items: demo)
            .padding()
    }
}
