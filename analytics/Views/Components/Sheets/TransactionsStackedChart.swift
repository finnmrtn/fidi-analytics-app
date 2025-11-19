import SwiftUI
import Charts

struct StackedSeriesPoint: Identifiable {
    let id = UUID()
    let date: Date
    let parts: [StackedSeriesPart]
}

struct StackedSeriesPart: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let color: Color
}

enum TimeBucket {
    case day, week, month
}

struct TimeBucketer {
    func bucket(for date: Date) -> TimeBucket {
        // Minimal stub implementation
        return .day
    }
}

struct TransactionsStackedChart: View {
    @Binding var selectedDate: Date?
    @Binding var selectedXPosition: CGFloat?
    let series: [StackedSeriesPoint]
    let bucketer: TimeBucketer
    let currentBucket: TimeBucket

    @State private var chartFrame: CGRect = .zero

    var body: some View {
        GeometryReader { geo in
            Chart {
                ForEach(series) { point in
                    ForEach(point.parts) { part in
                        BarMark(
                            x: .value("Date", point.date),
                            y: .value("Value", part.value)
                        )
                        .foregroundStyle(part.color)
                        .position(by: .stacked)
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                GeometryReader { geo2 in
                    Color.clear
                        .onAppear {
                            chartFrame = geo2.frame(in: .local)
                        }
                        .onChange(of: geo2.size) { _ in
                            chartFrame = geo2.frame(in: .local)
                        }
                }
            )
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

        TransactionsStackedChart(
            selectedDate: .constant(nil),
            selectedXPosition: .constant(nil),
            series: series,
            bucketer: TimeBucketer(),
            currentBucket: .day
        )
        .frame(height: 300)
        .padding()
    }
}
