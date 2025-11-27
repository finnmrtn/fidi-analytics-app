import SwiftUI
import Charts

struct PriceLineChartView: View {
    struct PricePoint: Identifiable {
        let id = UUID()
        let date: Date
        let price: Double
    }

    let data: [PricePoint]
    let startDate: Date?
    let endDate: Date?

    @State private var selectedDate: Date? = nil
    @State private var selectedPoint: PricePoint? = nil

    private let bucketer = TimeBucketer()
    private let calendar = Calendar.current

    // Choose a bucket size; adjust as needed
    enum TimeBucket {
        case hour, day
    }

    private var bucket: TimeBucket {
        // Prefer filter range if provided; fallback to data range
        let first = startDate ?? data.first?.date
        let last = endDate ?? data.last?.date
        guard let first, let last else { return .hour }
        let span = last.timeIntervalSince(first)
        return span > 2 * 24 * 3600 ? .day : .hour
    }

    private func bucketStart(for date: Date) -> Date {
        switch bucket {
        case .hour:
            return bucketer.bucketStart(for: date, bucket: .hour, calendar: calendar)
        case .day:
            return bucketer.bucketStart(for: date, bucket: .day, calendar: calendar)
        }
    }

    private func nearestPoint(to date: Date) -> PricePoint? {
        guard !data.isEmpty else { return nil }
        // Binary search for nearest by date
        var low = 0
        var high = data.count - 1
        while low < high {
            let mid = (low + high) / 2
            if data[mid].date < date {
                low = mid + 1
            } else {
                high = mid
            }
        }
        let idx = low
        if idx == 0 { return data.first }
        if idx >= data.count { return data.last }
        let prev = data[idx - 1]
        let curr = data[idx]
        return abs(prev.date.timeIntervalSince(date)) < abs(curr.date.timeIntervalSince(date)) ? prev : curr
    }

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.25), Color.accentColor.opacity(0.02)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var lineGradient: LinearGradient {
        LinearGradient(
            colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var lineStrokeStyle: StrokeStyle { StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round) }

    private func axisLabelText(for date: Date) -> Text {
        switch bucket {
        case .hour:
            return Text(date, format: .dateTime.hour(.twoDigits(amPM: .omitted)))
        case .day:
            return Text(date, format: .dateTime.day().month(.abbreviated))
        }
    }

    init(data: [(date: Date, price: Double)], startDate: Date? = nil, endDate: Date? = nil) {
        self.data = data.map { PricePoint(date: $0.date, price: $0.price) }
        self.startDate = startDate
        self.endDate = endDate
    }

    var body: some View {
        Chart(data) { point in
            AreaMark(
                x: .value("Time", point.date),
                y: .value("Price", point.price)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(areaGradient)

            LineMark(
                x: .value("Time", point.date),
                y: .value("Price", point.price)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(lineStrokeStyle)
            .foregroundStyle(lineGradient)

            if let selectedDate {
                RuleMark(x: .value("Selected", selectedDate))
                    .foregroundStyle(Color.accentColor.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, spacing: 0) {
                        if let point = selectedPoint {
                            VStack(spacing: 4) {
                                Text(point.date, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.4f", point.price))
                                    .font(.caption)
                                    .bold()
                            }
                            .padding(8)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
            }
        }
        .chartXSelection(value: $selectedDate)
        .onChange(of: selectedDate) { _, newValue in
            if let d = newValue {
                selectedPoint = nearestPoint(to: d)
            } else {
                selectedPoint = nil
            }
        }
        .chartXAxis {
            // Precompute tick values outside of the AxisContentBuilder to avoid control flow inside the builder
            let firstDate = startDate ?? data.first?.date
            let lastDate = endDate ?? data.last?.date
            let span = (firstDate != nil && lastDate != nil) ? lastDate!.timeIntervalSince(firstDate!) : 0

            let computedTicks: [Date] = {
                // We want at most 4 ticks, evenly distributed across the span
                let maxTicks = 4

                guard let first = firstDate, let last = lastDate, first <= last else {
                    return []
                }

                if bucket == .hour, span <= 24 * 3600 {
                    // Align to 6-hour boundaries to create up to 4 buckets over 24h
                    let cal = calendar
                    let firstHour = cal.component(.hour, from: first)
                    let alignedHour = (firstHour / 6) * 6
                    let startAligned = cal.date(bySettingHour: alignedHour, minute: 0, second: 0, of: first) ?? first
                    var t = startAligned
                    var result: [Date] = []
                    while t <= last {
                        result.append(t)
                        t = cal.date(byAdding: .hour, value: 6, to: t) ?? t.addingTimeInterval(6 * 3600)
                    }
                    if result.isEmpty { return [first, last].sorted() }
                    if result.count <= maxTicks { return result }
                    // Downsample to maxTicks (keep first and last, spread evenly)
                    let count = result.count
                    if maxTicks <= 2 { return [result.first!, result.last!].uniquedSorted() }
                    var sampled: [Date] = []
                    for i in 0..<maxTicks {
                        let idx = Int(round(Double(i) * Double(count - 1) / Double(maxTicks - 1)))
                        sampled.append(result[idx])
                    }
                    return Array(Set(sampled)).sorted()
                } else {
                    // Day bucket: compute bucket starts and then limit to max 4 evenly spaced ticks
                    let dates = data.map { bucketStart(for: $0.date) }
                    let unique = Array(Set(dates)).sorted()
                    if unique.isEmpty { return [first, last].sorted() }
                    if unique.count <= maxTicks { return unique }
                    // Downsample to maxTicks (keep first and last, spread evenly)
                    let count = unique.count
                    if maxTicks <= 2 { return [unique.first!, unique.last!] }
                    var sampled: [Date] = []
                    for i in 0..<maxTicks {
                        let idx = Int(round(Double(i) * Double(count - 1) / Double(maxTicks - 1)))
                        sampled.append(unique[idx])
                    }
                    return Array(Set(sampled)).sorted()
                }
            }()

            // Helper to ensure two elements unique & sorted when needed

            AxisMarks(values: computedTicks) { value in
                AxisGridLine().foregroundStyle(Color.clear)
                AxisTick()
                AxisValueLabel {
                    if let d = value.as(Date.self) {
                        axisLabelText(for: d)
                    }
                }
            }
        }
        .chartYAxis(content: {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.primary.opacity(0.06))
            }
        })
        .chartPlotStyle(content: { plot in
            let bg = AnyShapeStyle(.ultraThinMaterial)
            plot
                .background(bg)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        })
    }
}

private extension Array where Element == Date {
    func uniquedSorted() -> [Date] {
        Array(Set(self)).sorted()
    }
}

#Preview("PriceLineChartView") {
    let now = Date()
    let sample: [(date: Date, price: Double)] = (0..<24).map { i in
        let date = Calendar.current.date(byAdding: .hour, value: -i, to: now) ?? now
        let noise: Double = Double.random(in: -0.002...0.003)
        let wave: Double = 0.015 * sin(Double(i) / 4.0)
        let base: Double = 0.05
        let price = base + noise + wave
        return (date: date, price: price)
    }.sorted { lhs, rhs in
        lhs.date < rhs.date
    }

    return PriceLineChartView(data: sample)
        .frame(height: 180)
        .padding()
}
