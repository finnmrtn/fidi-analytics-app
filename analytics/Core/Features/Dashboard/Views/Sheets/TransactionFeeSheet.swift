//
//  TxFeesSheet.swift
//  analytics
//
//  Created by Assistant on 27.10.25.
//

import SwiftUI
import Charts

struct TransactionFeeSheet: View {
    var viewModel: AnalyticsViewModel
    @Binding var showSheet: Bool
    var filterViewModel: TimeFilterViewModel
    var selectionStore: SharedSelectionStore

    @State private var showFilterPopup: Bool = false

    var body: some View {
        // Use real directory names for projects via dappId lookup (kept for consistency in other places)
        let _ = nameByDappId()

        // Top 9 + Other aggregated over the past 2 years -> single stacked bar
        let points = top9PlusOtherFeesLastTwoYears(metrics: viewModel.filteredDAppMetrics, now: Date(), calendar: .current)

        // Keep using ChartAggregation to preserve color domain behavior
        let aggregated = ChartAggregation.aggregateTopNWithOther(from: points, topCount: 9, bucket: .month, calendar: .current)
        let data = aggregated.data
        let colorDomain = aggregated.colorDomain

        MetricSheetTemplate(
            title: "Transaction Fees",
            metric: "Transaction Fees",
            metricValue: formatAbbreviated(viewModel.aggregatedTradingFees, asCurrency: true),
            filterViewModel: filterViewModel,
            selectionStore: selectionStore,
            filterButtonLabel: "Filter",
            onClose: { showSheet = false },
            onOpenFilter: { showFilterPopup = true },
            icon: Image("networkfee"),
            iconTint: Color(hex: "#2F2F2F"),
            iconStrokeColor: Color(hex: "#DCDEE1"),
            backgroundColor: Color(hex: "#2F2F2F")
        ) {
            StackedBarChartView(
                data: data,
                colorDomain: colorDomain,
                yLabel: "Fees",
                minHeight: 280
            )
        }.padding(16)
    }

    private func formatAbbreviated(_ value: Double, asCurrency: Bool = true, currencyCode: String = "USD") -> String {
        let absVal = abs(value)
        let sign = value < 0 ? "-" : ""
        let formatted: String
        switch absVal {
        case 1_000_000_000...:
            formatted = String(format: "%.1fB", absVal / 1_000_000_000)
        case 1_000_000...:
            formatted = String(format: "%.1fM", absVal / 1_000_000)
        case 1_000...:
            formatted = String(format: "%.1fk", absVal / 1_000)
        default:
            formatted = String(format: "%.0f", absVal)
        }
        if asCurrency {
            return sign + "$" + formatted
        } else {
            return sign + formatted
        }
    }
}
