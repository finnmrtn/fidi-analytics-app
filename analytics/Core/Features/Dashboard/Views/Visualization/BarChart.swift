import SwiftUI
import Charts

private let DefaultChartPalette: [Color] = [
    Color("GraphColor2"),
    Color("GraphColor6"),
    Color("GraphColor5"),
    Color("GraphColor7"),
    Color("GraphColor4"),
    Color("GraphColor3"),
    Color("GraphColor1"),
    Color("GraphColor8"),
    Color("GraphColor9"),
    Color("GraphColor10")
]

/// Ensures that if the domain contains "Other", it is mapped to the final color in the palette
/// and that domain and range lengths match. If range is shorter, it repeats; if longer, it trims.
private func normalizedScale(domain: [String], range: [Color]?) -> (domain: [String], range: [Color]) {
    let hasOther = domain.contains("Other")
    // Start with either provided range or default palette
    var baseRange = (range ?? DefaultChartPalette)
    if baseRange.isEmpty { baseRange = DefaultChartPalette }

    // Ensure length alignment by repeating or trimming
    func adjustedRange(for count: Int) -> [Color] {
        if baseRange.count == count { return baseRange }
        if baseRange.count > count { return Array(baseRange.prefix(count)) }
        // repeat colors to reach count
        var out: [Color] = []
        var i = 0
        while out.count < count {
            out.append(baseRange[i % baseRange.count])
            i += 1
        }
        return out
    }

    var outDomain = domain
    var outRange = adjustedRange(for: outDomain.count)

    // Pin "Other" to the last color to be consistent across charts
    if hasOther, let otherIndex = outDomain.firstIndex(of: "Other") {
        let lastIndex = outRange.count - 1
        // Swap color at otherIndex with the last color position
        if otherIndex != lastIndex {
            outDomain.swapAt(otherIndex, lastIndex)
            outRange.swapAt(otherIndex, lastIndex)
        }
    }

    return (outDomain, outRange)
}

/// A reusable stacked bar chart for time series aggregated by category.
/// - Parameters:
///   - data: Array of data points (date, value, category)
///   - colorDomain: Category ordering used for legend and color mapping
///   - colorRange: Colors corresponding to the domain order
///   - xUnit: DateComponents.Unit for x-axis bucketing (e.g., .month)
///   - yLabel: Axis label for y values
///   - minHeight: Minimum height of the chart container
public struct StackedBarChartPoint: Identifiable {
    public let id: UUID
    public let date: Date
    public let value: Double
    public let category: String

    public init(id: UUID = UUID(), date: Date, value: Double, category: String) {
        self.id = id
        self.date = date
        self.value = value
        self.category = category
    }
}

public struct StackedBarChartView: View {
    private let data: [StackedBarChartPoint]
    private let colorDomain: [String]
    private let colorRangeOpt: [Color]?
    private let xUnit: Calendar.Component
    private let yLabel: String
    private let minHeight: CGFloat

    public init(
        data: [StackedBarChartPoint],
        colorDomain: [String],
        colorRange: [Color]? = nil,
        xUnit: Calendar.Component = .month,
        yLabel: String,
        minHeight: CGFloat = 280
    ) {
        self.data = data
        self.colorDomain = colorDomain
        self.colorRangeOpt = colorRange
        self.xUnit = xUnit
        self.yLabel = yLabel
        self.minHeight = minHeight
    }

    public var body: some View {
        GeometryReader { proxy in
            let availableHeight = max(proxy.size.height, minHeight - 40)
            let scale = normalizedScale(domain: colorDomain, range: colorRangeOpt)
            Chart(data) { point in
                BarMark(
                    x: .value("Date", point.date, unit: xUnit),
                    y: .value(yLabel, point.value)
                )
                .foregroundStyle(by: .value("Category", point.category))
            }
            .chartLegend(.visible)
            .chartForegroundStyleScale(domain: scale.domain, range: scale.range)
            .chartXAxis {
                AxisMarks(values: .stride(by: xUnit)) {
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
            .frame(height: availableHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(minHeight: minHeight)
    }
}

