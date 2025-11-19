import SwiftUI

// A generic data point protocol to match the key paths used in TxFeesSheet
// We keep it simple by constraining to the properties accessed via key paths.
public struct MetricDataPoint<Category> {
    public let date: Date
    public let viewCount: Double
    public let category: Category
    public init(date: Date, viewCount: Double, category: Category) {
        self.date = date
        self.viewCount = viewCount
        self.category = category
    }
}

struct MetricBarChartSheet<Data, Category>: View {
    // Inputs matching usage in TxFeesSheet
    let title: String
    let aggregationLabel: String
    let aggregationFormattedValue: String
    let data: [Data]
    let xDate: KeyPath<Data, Date>
    let yValue: KeyPath<Data, Double>
    let categoryName: KeyPath<Data, String>
    let colorScale: [String: Color]

    // Axis and formatting inputs (not fully used in placeholder)
    let xStride: Calendar.Component
    let xLabelFormat: Date.FormatStyle

    let close: () -> Void
    let filterButtonLabel: String
    let onOpenFilter: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(title)
                    .font(.title3.weight(.semibold))
                Spacer()
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.headline)
                }
                .accessibilityLabel("Close")
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(aggregationLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(aggregationFormattedValue)
                    .font(.title3.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Placeholder chart area
            VStack(alignment: .leading, spacing: 8) {
                Text("Chart")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        // Simple list rendering of data as a placeholder for the chart
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                                    let name = item[keyPath: categoryName]
                                    let value = item[keyPath: yValue]
                                    let date = item[keyPath: xDate]
                                    HStack {
                                        Circle()
                                            .fill(colorScale[name] ?? .gray)
                                            .frame(width: 8, height: 8)
                                        Text("\(date.formatted(date: .abbreviated, time: .omitted)) • \(name)")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(value.formatted())
                                            .font(.footnote.monospacedDigit())
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(8)
                        }
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
            }

            HStack {
                Button(action: onOpenFilter) {
                    HStack(spacing: 8) {
                        Text(filterButtonLabel)
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.down")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(16)
    }
}

#if DEBUG
struct MetricBarChartSheet_Previews: PreviewProvider {
    struct SampleItem { let date: Date; let viewCount: Double; let category: (name: String) }
    static var sample: [SampleItem] = [
        .init(date: .now, viewCount: 10, category: (name: "Organic")),
        .init(date: .now.addingTimeInterval(-86400*3), viewCount: 12, category: (name: "Paid")),
        .init(date: .now.addingTimeInterval(-86400*7), viewCount: 7, category: (name: "Referral"))
    ]
    static var previews: some View {
        MetricBarChartSheet(
            title: "Transaction Fees",
            aggregationLabel: "Average",
            aggregationFormattedValue: "123.45",
            data: sample,
            xDate: \.date,
            yValue: \.viewCount,
            categoryName: \.category.name,
            colorScale: ["Organic": .green, "Paid": .blue, "Referral": .orange],
            xStride: .month,
            xLabelFormat: .dateTime.month(.abbreviated),
            close: {},
            filterButtonLabel: "Average",
            onOpenFilter: {}
        )
        .previewLayout(.sizeThatFits)
    }
}
#endif
