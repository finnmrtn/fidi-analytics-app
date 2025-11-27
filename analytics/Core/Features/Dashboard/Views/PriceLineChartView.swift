import SwiftUI
import Charts

struct PriceLineChartView: View {
    struct PricePoint: Identifiable {
        let id = UUID()
        let date: Date
        let price: Double
    }

    let data: [PricePoint]

    init(data: [(date: Date, price: Double)]) {
        self.data = data.map { PricePoint(date: $0.date, price: $0.price) }
    }

    var body: some View {
        Chart(data) { point in
            AreaMark(
                x: .value("Time", point.date),
                y: .value("Price", point.price)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(LinearGradient(
                colors: [Color.accentColor.opacity(0.25), Color.accentColor.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            ))

            LineMark(
                x: .value("Time", point.date),
                y: .value("Price", point.price)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round))
            .foregroundStyle(LinearGradient(
                colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(.clear)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine().foregroundStyle(.primary.opacity(0.06))
            }
        }
        .chartPlotStyle { plot in
            plot
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

#Preview("PriceLineChartView") {
    let now = Date()
    let sample: [(date: Date, price: Double)] = (0..<24).map { i in
        (Calendar.current.date(byAdding: .hour, value: -i, to: now) ?? now, 0.05 + Double.random(in: -0.002...0.003) + 0.015 * sin(Double(i) / 4.0))
    }.sorted { $0.date < $1.date }

    return PriceLineChartView(data: sample)
        .frame(height: 180)
        .padding()
}
