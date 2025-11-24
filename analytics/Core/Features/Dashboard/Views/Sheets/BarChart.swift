import SwiftUI
import Charts

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
    private let colorRange: [Color]
    private let xUnit: Calendar.Component
    private let yLabel: String
    private let minHeight: CGFloat

    public init(
        data: [StackedBarChartPoint],
        colorDomain: [String],
        colorRange: [Color],
        xUnit: Calendar.Component = .month,
        yLabel: String,
        minHeight: CGFloat = 280
    ) {
        self.data = data
        self.colorDomain = colorDomain
        self.colorRange = colorRange
        self.xUnit = xUnit
        self.yLabel = yLabel
        self.minHeight = minHeight
    }

    public var body: some View {
        GeometryReader { proxy in
            let availableHeight = max(proxy.size.height, minHeight - 40)
            Chart(data) { point in
                BarMark(
                    x: .value("Date", point.date, unit: xUnit),
                    y: .value(yLabel, point.value)
                )
                .foregroundStyle(by: .value("Category", point.category))
            }
            .chartLegend(.visible)
            .chartForegroundStyleScale(domain: colorDomain, range: colorRange)
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
