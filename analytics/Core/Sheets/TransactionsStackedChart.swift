import SwiftUI
import Charts

enum StackedChartStyle {
    case stackedBars
    case stackedArea
}

struct StackedSeriesPoint: Identifiable {
    let id = UUID()
    let date: Date
    let parts: [StackedSeriesPart]
}

struct StackedBar: Identifiable {
    let id = UUID()
    let date: Date
    let name: String
    let value: Double
    let color: Color
}

struct TransactionsStackedChart: View {
    @Binding var selectedDate: Date?
    @Binding var selectedXPosition: CGFloat?
    let series: [StackedSeriesPoint]
    let bucketer: TimeBucketer
    let currentBucket: TimeBucket
    let style: StackedChartStyle

    var body: some View {
        GeometryReader { geo in
            let flatBars: [StackedBar] = series.flatMap { point in
                point.parts.map { part in
                    StackedBar(date: point.date, name: part.name, value: Double(part.value), color: part.color)
                }
            }

            Group {
                switch style {
                case .stackedBars:
                    Chart(flatBars) { bar in
                        BarMark(
                            x: .value("Date", bar.date),
                            y: .value("Value", bar.value)
                        )
                        .foregroundStyle(bar.color)
                        .position(by: .value("Category", bar.name))
                    }
                case .stackedArea:
                    Chart(flatBars) { bar in
                        AreaMark(
                            x: .value("Date", bar.date),
                            y: .value("Value", bar.value)
                        )
                        .foregroundStyle(by: .value("Category", bar.name))
                        .interpolationMethod(.catmullRom)
                        .position(by: .value("Category", bar.name))
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                selectedXPosition = value.location.x
                                selectedDate = date(at: value.location.x, in: geo.size.width)
                            }
                            .onEnded { value in
                                selectedXPosition = value.location.x
                                selectedDate = date(at: value.location.x, in: geo.size.width)
                            }
                    )
            )
        }
    }

    private func date(at xPosition: CGFloat, in width: CGFloat) -> Date? {
        guard !series.isEmpty else { return nil }
        let sortedSeries = series.sorted { $0.date < $1.date }

        // Calculate step width between points
        let minX: CGFloat = 0
        let maxX: CGFloat = width
        let count = sortedSeries.count

        if count == 1 {
            return sortedSeries[0].date
        }

        // Map xPosition to closest index
        let step = maxX / CGFloat(count - 1)
        let index = Int(round(xPosition / step))
        let clampedIndex = max(0, min(count - 1, index))

        return sortedSeries[clampedIndex].date
    }
}

struct TransactionsStackedChart_Previews: PreviewProvider {
    static var previews: some View {
        let parts1 = [
            StackedSeriesPart(name: "Food", value: 20, color: .red),
            StackedSeriesPart(name: "Transport", value: 10, color: .blue),
            StackedSeriesPart(name: "Other", value: 5, color: .green)
        ]
        let parts2 = [
            StackedSeriesPart(name: "Food", value: 15, color: .red),
            StackedSeriesPart(name: "Transport", value: 12, color: .blue),
            StackedSeriesPart(name: "Other", value: 7, color: .green)
        ]
        let parts3 = [
            StackedSeriesPart(name: "Food", value: 25, color: .red),
            StackedSeriesPart(name: "Transport", value: 8, color: .blue),
            StackedSeriesPart(name: "Other", value: 12, color: .green)
        ]

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let series = [
            StackedSeriesPoint(date: calendar.date(byAdding: .day, value: -2, to: today)!, parts: parts1),
            StackedSeriesPoint(date: calendar.date(byAdding: .day, value: -1, to: today)!, parts: parts2),
            StackedSeriesPoint(date: today, parts: parts3)
        ]

        return VStack(spacing: 24) {
            // Stacked Bars (for Transaction Fees)
            TransactionsStackedChart(
                selectedDate: .constant(nil),
                selectedXPosition: .constant(nil),
                series: series,
                bucketer: TimeBucketer(),
                currentBucket: .day,
                style: .stackedBars
            )
            .frame(height: 220)
            .padding()

            // Stacked Area (for Transaction Sheet)
            TransactionsStackedChart(
                selectedDate: .constant(nil),
                selectedXPosition: .constant(nil),
                series: series,
                bucketer: TimeBucketer(),
                currentBucket: .day,
                style: .stackedArea
            )
            .frame(height: 220)
            .padding()
        }
    }
}
