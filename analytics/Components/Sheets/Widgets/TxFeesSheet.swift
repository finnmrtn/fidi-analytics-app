import SwiftUI

struct TxFeesSheet: View {
    var viewModel: AnalyticsViewModel
    @Bindable var filterViewModel: TimeFilterViewModel
    @State private var showFilterSheet = false

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
        let items = rankedItems()
        let total = items.reduce(0) { $0 + $1.value }
        return WidgetTemplate(
            type: .txFees,
            title: WidgetType.txFees.title,
            aggregationLabel: viewModel.selectedAggregation.rawValue,
            aggregationValue: MetricFormatter.abbreviatedCurrency(total),
            filterButtonLabel: viewModel.selectedAggregation.rawValue,
            content: {
                AnyView(
                    RankedBarList(items: items)
                )
            }
        )
    }

    private func rankedItems() -> [RankedBarItem] {
        let metrics = viewModel.filteredDAppMetrics
        guard !metrics.isEmpty else { return [] }

        let directory = mockDirectoryItems()
        let nameById = Dictionary(uniqueKeysWithValues: directory.map { ($0.id, $0.name) })
        let grouped = Dictionary(grouping: metrics, by: { $0.dappId })

        let aggregated = grouped.compactMap { (id, rows) -> (String, String, Double)? in
            let value = aggregate(values: rows.map { $0.tradingFees ?? 0 })
            guard value > 0 else { return nil }
            return (id, nameById[id] ?? "Project", value)
        }
        .sorted { $0.2 > $1.2 }
        .prefix(10)

        return aggregated.enumerated().map { index, entry in
            let color = ChartTheme.transactionsColors[min(index, ChartTheme.transactionsColors.count - 1)]
            return RankedBarItem(id: entry.0, name: entry.1, value: entry.2, color: color)
        }
    }

    private func aggregate(values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        switch viewModel.selectedAggregation {
        case .sum:
            return values.reduce(0, +)
        case .avg:
            return values.reduce(0, +) / Double(values.count)
        case .med:
            let sorted = values.sorted()
            if values.count % 2 == 0 {
                let mid = values.count / 2
                return (sorted[mid - 1] + sorted[mid]) / 2
            } else {
                return sorted[values.count / 2]
            }
        case .max:
            return values.max() ?? 0
        case .min:
            return values.min() ?? 0
        }
    }
}
