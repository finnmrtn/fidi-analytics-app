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
        contentView()
    }

    @ViewBuilder
    private func contentView() -> some View {
        let flatBars = makeFlatBars()

        switch style {
        case .stackedBars:
            stackedBarsChart(flatBars: flatBars)
        case .stackedArea:
            stackedAreaChart(flatBars: flatBars)
        }
    }

    private func makeFlatBars() -> [StackedBar] {
        series.flatMap { point in
            point.parts.map { part in
                StackedBar(date: point.date, name: part.name, value: Double(part.value), color: part.color)
            }
        }
    }

    private func preferredDomain(from flatBars: [StackedBar]) -> [String] {
        // Names present in data
        let present = Array(Set(flatBars.map { $0.name }))
        // Preferred order from MockData (top projects), fall back to empty if unavailable
        let preferred = mockTopGasFeesByProjectTop10().map { $0.name }
        // Keep preferred names that are present
        var domain: [String] = preferred.filter { present.contains($0) }
        // Append any remaining present names not covered by preferred, in stable sorted order
        let remaining = present.filter { !domain.contains($0) }.sorted()
        domain.append(contentsOf: remaining)
        // Ensure Others exists and is at the end so it stacks at the top
        if present.contains("Others") {
            domain.removeAll(where: { $0 == "Others" })
            domain.append("Others")
        }
        return domain
    }

    @ViewBuilder
    private func stackedBarsChart(flatBars: [StackedBar]) -> some View {
        Chart {
            ForEach(flatBars) { bar in
                BarMark(
                    x: .value("Date", bar.date),
                    y: .value("Value", bar.value)
                )
                .foregroundStyle(by: .value("Category", bar.name))
                .position(by: .value("Category", bar.name))
            }
            if let selectedDate {
                RuleMark(x: .value("Selected Date", selectedDate))
                    .foregroundStyle(Color.highlight.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 3]))
            }
        }
        .chartXScale(domain: .automatic(includesZero: false))
        .chartYScale(domain: .automatic(includesZero: true))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine().foregroundStyle(.secondary.opacity(0.25))
                AxisTick().foregroundStyle(.secondary.opacity(0.6))
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(.secondary.opacity(0.2))
                AxisTick().foregroundStyle(.secondary.opacity(0.6))
                AxisValueLabel()
            }
        }
        .chartPlotStyle { plot in
            plot
                .padding(.top, 4)
                .padding(.bottom, 4)
                .padding(.leading, 6)
                .padding(.trailing, 0)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, minHeight: 450)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(Color.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x - geo[proxy.plotAreaFrame].origin.x
                                selectedXPosition = value.location.x
                                if let date: Date = proxy.value(atX: x) {
                                    selectedDate = date
                                }
                            }
                            .onEnded { value in
                                let x = value.location.x - geo[proxy.plotAreaFrame].origin.x
                                selectedXPosition = value.location.x
                                if let date: Date = proxy.value(atX: x) {
                                    selectedDate = date
                                }
                            }
                    )
            }
        }
    }

    @ViewBuilder
    private func stackedAreaChart(flatBars: [StackedBar]) -> some View {
        Chart {
            ForEach(flatBars) { bar in
                AreaMark(
                    x: .value("Date", bar.date),
                    y: .value("Value", bar.value),
                    stacking: .standard
                )
                .foregroundStyle(by: .value("Category", bar.name))
                .interpolationMethod(.monotone)
            }
            if let selectedDate {
                RuleMark(x: .value("Selected Date", selectedDate))
                    .foregroundStyle(Color.highlight.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 3]))
            }
        }
        .chartForegroundStyleScale(
            domain: preferredDomain(from: flatBars),
            range: {
                let names = preferredDomain(from: flatBars)
                let palette: [Color] = [
                    Color("GraphColor1"), Color("GraphColor2"), Color("GraphColor3"),
                    Color("GraphColor4"), Color("GraphColor5"), Color("GraphColor6"),
                    Color("GraphColor7"), Color("GraphColor8"), Color("GraphColor9"),
                    Color("GraphColor10")
                ]
                return names.enumerated().map { index, name in
                    let base: Color
                    if name == "Others" {
                        base = Color.shade
                    } else {
                        base = palette[index % palette.count]
                    }
                    let g = Gradient(stops: [
                        .init(color: base.opacity(1.0), location: 0.0),
                        .init(color: base.opacity(1.0), location: 1.0)
                    ])
                    return AnyGradient(g)
                }
            }()
        )
        .chartLegend(position: .bottom)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine().foregroundStyle(.secondary.opacity(0.25))
                AxisTick().foregroundStyle(.secondary.opacity(0.6))
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(.secondary.opacity(0.2))
                AxisTick().foregroundStyle(.secondary.opacity(0.6))
                AxisValueLabel()
            }
        }
        .chartXScale(domain: .automatic(includesZero: false))
        .chartYScale(domain: .automatic(includesZero: true))
        .chartPlotStyle { plot in
            plot
                .padding(.top, 4)
                .padding(.bottom, 4)
                .padding(.leading, 6)
                .padding(.trailing, 0)
        }
        .padding(.vertical, 4)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, minHeight: 450)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                handleChartInteraction(gesture: gesture, geometry: geometry, proxy: proxy)
                            }
                            .onEnded { gesture in
                                handleChartInteraction(gesture: gesture, geometry: geometry, proxy: proxy)
                            }
                    )
            }
        }
    }

    private func handleChartInteraction(gesture: DragGesture.Value, geometry: GeometryProxy, proxy: ChartProxy) {
        let xPosition = gesture.location.x - geometry[proxy.plotAreaFrame].origin.x
        selectedXPosition = gesture.location.x
        
        if let date: Date = proxy.value(atX: xPosition) {
            selectedDate = date
        }
    }
    
    private func date(at xPosition: CGFloat, in width: CGFloat) -> Date? {
        guard !series.isEmpty else { return nil }
        let sortedSeries = series.sorted { $0.date < $1.date }

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
