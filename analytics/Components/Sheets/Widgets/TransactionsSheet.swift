import SwiftUI
import Charts

struct TransactionsSheet: View {
    var viewModel: AnalyticsViewModel
    @Bindable var filterViewModel: TimeFilterViewModel
    @State private var showFilterSheet = false
    @State private var selectedDate: Date?
    @State private var selectedXPosition: CGFloat?

    private let bucketer = MetricTimeBucketer()

    var body: some View {
        WidgetSheet(
            template: template,
            viewModel: viewModel,
            filterViewModel: filterViewModel,
            showFilterSheet: $showFilterSheet
        )
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(24)
        .presentationDragIndicator(.visible)
    }

    private var template: WidgetTemplate {
        WidgetTemplate(
            type: .transactions,
            title: WidgetType.transactions.title,
            aggregationLabel: viewModel.selectedAggregation.rawValue,
            aggregationValue: MetricFormatter.abbreviatedCurrency(viewModel.aggregatedTradingVolume),
            filterButtonLabel: viewModel.selectedAggregation.rawValue,
            content: {
                AnyView(
                    TransactionsWidgetContent(
                        viewModel: viewModel,
                        selectedDate: $selectedDate,
                        selectedXPosition: $selectedXPosition,
                        bucketer: bucketer
                    )
                )
            }
        )
    }
}

private struct TransactionsWidgetContent: View {
    var viewModel: AnalyticsViewModel
    @Binding var selectedDate: Date?
    @Binding var selectedXPosition: CGFloat?
    let bucketer: MetricTimeBucketer

    private var currentBucket: MetricTimeBucket {
        let metrics = viewModel.filteredDAppMetrics
        guard let start = metrics.first?.date, let end = metrics.last?.date else { return .day }
        return bucketer.bucket(from: start, to: end)
    }

    private var stackedSeries: [(date: Date, parts: [(name: String, value: Double, color: Color)])] {
        let metrics = viewModel.filteredDAppMetrics
        guard !metrics.isEmpty else { return [] }

        let directory = mockDirectoryItems()
        let nameById = Dictionary(uniqueKeysWithValues: directory.map { ($0.id, $0.name) })
        let grouped = Dictionary(grouping: metrics, by: { $0.dappId })

        let totals: [(id: String, name: String, total: Double)] = grouped.map { (id, rows) in
            let sum = rows.reduce(0) { $0 + ($1.tradingFees ?? 0) }
            return (id, nameById[id] ?? "Project", sum)
        }
        .filter { $0.total > 0 }
        .sorted { $0.total > $1.total }
        .prefix(10)

        guard !totals.isEmpty else { return [] }

        let topIds = totals.map { $0.id }
        let byBucket = Dictionary(grouping: metrics.filter { topIds.contains($0.dappId) }, by: { bucketer.bucketStart(for: $0.date, bucket: currentBucket) })
        let sortedKeys = byBucket.keys.sorted()

        return sortedKeys.compactMap { key -> (Date, [(String, Double, Color)])? in
            let rows = byBucket[key] ?? []
            let perDapp = Dictionary(grouping: rows, by: { $0.dappId }).mapValues { series in
                series.reduce(0) { $0 + ($1.tradingFees ?? 0) }
            }

            let parts: [(String, Double, Color)] = topIds.enumerated().compactMap { (idx, id) in
                let value = perDapp[id] ?? 0
                guard value > 0 else { return nil }
                let color = ChartTheme.transactionsColors[min(idx, ChartTheme.transactionsColors.count - 1)]
                return (nameById[id] ?? "Project", value, color)
            }

            guard !parts.isEmpty else { return nil }
            return (key, parts)
        }
    }

    private var hasValidChartData: Bool {
        stackedSeries.contains { bucket in
            bucket.parts.contains { $0.value > 0 }
        }
    }

    private var seriesPoints: [StackedSeriesPoint] {
        stackedSeries.map { bucket in
            StackedSeriesPoint(
                date: bucket.date,
                parts: bucket.parts.map { part in
                    StackedSeriesPart(name: part.0, value: part.1, color: part.2)
                }
            )
        }
    }

    private static let longDayMonthYearFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .none
        return df
    }()

    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeaderView(totalText: MetricFormatter.abbreviatedCurrency(viewModel.aggregatedTradingVolume))

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 8)
                    .overlay(
                        VStack(spacing: 0) {
                            if let selectedDate {
                                ChartTooltip(
                                    date: selectedDate,
                                    rows: seriesForDate(selectedDate),
                                    formatValue: { MetricFormatter.abbreviatedCurrency($0) },
                                    formatDate: { Self.longDayMonthYearFormatter.string(from: $0) },
                                    formatTime: { Self.timeFormatter.string(from: $0) }
                                )
                            }

                            if hasValidChartData {
                                TransactionsStackedChart(
                                    selectedDate: $selectedDate,
                                    selectedXPosition: $selectedXPosition,
                                    series: seriesPoints,
                                    bucketer: bucketer,
                                    currentBucket: currentBucket,
                                    style: .stackedArea
                                )
                                .frame(height: 280)
                                .padding(.bottom, 8)
                            } else {
                                EmptyStateView()
                                    .frame(height: 280)
                            }
                        }
                    )
            }
        }
    }

    private func seriesForDate(_ date: Date) -> [ChartTooltipRow] {
        let bucketDate = bucketer.bucketStart(for: date, bucket: currentBucket)
        guard let bucket = stackedSeries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: bucketDate) }) else {
            return []
        }
        return bucket.parts.map { part in
            ChartTooltipRow(color: part.2, name: part.0, value: part.1)
        }
    }
}

private struct HeaderView: View {
    let totalText: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Transactions")
                .font(.headline)
            Spacer()
            Text(totalText)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No transaction data available")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Select a different time period")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
