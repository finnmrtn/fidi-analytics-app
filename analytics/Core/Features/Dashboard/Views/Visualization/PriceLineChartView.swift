import SwiftUI
import Charts

private extension View {
    @ViewBuilder
    func applyIf<T>(_ condition: Bool, transform: (Self) -> T) -> some View where T: View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

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

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 6
        f.minimumFractionDigits = 2
        return f
    }()

    init(data: [(date: Date, price: Double)], startDate: Date? = nil, endDate: Date? = nil) {
        self.data = data.map { PricePoint(date: $0.date, price: $0.price) }.sorted { $0.date < $1.date }
        self.startDate = startDate
        self.endDate = endDate
    }

    private var visibleData: [PricePoint] {
        guard !data.isEmpty else { return [] }
        let lo = startDate ?? data.first!.date
        let hi = endDate ?? data.last!.date
        return data.filter { $0.date >= lo && $0.date <= hi }
    }

    private var xDomain: ClosedRange<Date>? {
        guard let first = visibleData.first?.date, let last = visibleData.last?.date else { return nil }
        if first == last {
            return first.addingTimeInterval(-0.5)...last.addingTimeInterval(0.5)
        }
        return first...last
    }

    private var yDomain: ClosedRange<Double>? {
        guard let minV = visibleData.map(\.price).min(), let maxV = visibleData.map(\.price).max(), minV.isFinite, maxV.isFinite else { return nil }
        if minV == maxV { return (minV - 0.5)...(maxV + 0.5) }
        let pad = (maxV - minV) * 0.08
        return (minV - pad)...(maxV + pad)
    }

    var body: some View {
        Group {
            if !visibleData.isEmpty {
                Chart {
                    ForEach(visibleData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Price", point.price)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Color.accentColor)
                    }
                    if let selectedDate,
                       let nearest = visibleData.min(by: { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }) {
                        RuleMark(x: .value("Selected Date", nearest.date))
                            .foregroundStyle(.secondary)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        PointMark(
                            x: .value("Date", nearest.date),
                            y: .value("Price", nearest.price)
                        )
                        .symbolSize(60)
                        .foregroundStyle(Color.accentColor)
                        .annotation(position: .top, alignment: .leading) {
                            let priceText = numberFormatter.string(from: NSNumber(value: nearest.price)) ?? String(format: "%.4f", nearest.price)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(priceText).bold()
                                Text(dateFormatter.string(from: nearest.date))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(6)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks()
                }
                .chartYAxis {
                    AxisMarks(position: .trailing)
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = value.location
                                    if let date: Date = proxy.value(atX: location.x, as: Date.self) {
                                        selectedDate = date
                                    }
                                }
                                .onEnded { _ in
                                    selectedDate = nil
                                }
                            )
                    }
                }
                .chartXScale(domain: (xDomain ?? {
                    if let first = data.first?.date, let last = data.last?.date, first != last {
                        return first...last
                    } else if let only = data.first?.date {
                        return only.addingTimeInterval(-0.5)...only.addingTimeInterval(0.5)
                    } else {
                        let now = Date()
                        return now.addingTimeInterval(-0.5)...now.addingTimeInterval(0.5)
                    }
                }()))
                .chartYScale(domain: (yDomain ?? {
                    let allPrices = data.map { $0.price }
                    if let minV = allPrices.min(), let maxV = allPrices.max(), minV.isFinite, maxV.isFinite {
                        if minV == maxV { return (minV - 0.5)...(maxV + 0.5) }
                        let pad = (maxV - minV) * 0.08
                        return (minV - pad)...(maxV + pad)
                    } else {
                        return 0...1
                    }
                }()))
                .animation(.easeInOut(duration: 0.2), value: startDate)
                .animation(.easeInOut(duration: 0.2), value: endDate)
                .id("\(startDate?.timeIntervalSince1970 ?? -1)|\(endDate?.timeIntervalSince1970 ?? -1)|\(visibleData.count)")
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No data available")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 140)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )
            }
        }
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
