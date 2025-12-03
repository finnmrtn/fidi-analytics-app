//
//  UAWSheet.swift
//  analytics
//
//  Created by Finn Garrels on 27.10.25.
//

import SwiftUI
import Charts

struct UAWSheet: View {
    var viewModel: AnalyticsViewModel
    @Binding var showSheet: Bool
    var filterViewModel: TimeFilterViewModel
    var selectionStore: SharedSelectionStore

    @State private var showFilterPopup: Bool = false

    private var preparedChart: (data: [StackedBarChartPoint], colorDomain: [String]) {
        // Use real directory names for projects via dappId lookup
        let nameMap = nameByDappId()

        let cal = Calendar.current
        let now = Date()

        // Decide bucketing based on the filter timeframe if available via selectionStore/filterViewModel
        // If not directly available, default to monthly buckets over the last 12 months.
        // Here we implement a simple monthly bucketing for the last 12 months to ensure multiple bars.
        let monthsBack = 24
        var bucketAnchors: [Date] = []
        if let startOfThisMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) {
            for i in stride(from: monthsBack - 1, through: 0, by: -1) {
                if let d = cal.date(byAdding: .month, value: -i, to: startOfThisMonth) {
                    bucketAnchors.append(d)
                }
            }
        }

        // Build raw points per bucket: sum dau by project within each month
        var rawPoints: [(date: Date, value: Double, project: String)] = []
        for anchor in bucketAnchors {
            // month range: [anchor, nextMonth)
            let nextMonth = cal.date(byAdding: .month, value: 1, to: anchor) ?? anchor
            var sumByProject: [String: Double] = [:]
            for m in viewModel.filteredDAppMetrics where m.date >= anchor && m.date < nextMonth {
                let name = nameMap[m.dappId] ?? "Project"
                let v = m.dau ?? 0
                guard v != 0 else { continue }
                sumByProject[name, default: 0] += v
            }
            if !sumByProject.isEmpty {
                for (name, val) in sumByProject { rawPoints.append((date: anchor, value: val, project: name)) }
            }
        }

        // Aggregate into Top N + Other while preserving color domain across all buckets
        let aggregated = ChartAggregation.aggregateTopNWithOther(from: rawPoints, topCount: 9, bucket: .month, calendar: cal)
        return (aggregated.data, aggregated.colorDomain)
    }

    var body: some View {
        let (data, colorDomain) = preparedChart

        MetricSheetTemplate(
            title: "Unique Active Wallets",
            metric: "Unique Active Wallets",
            metricValue: viewModel.aggregatedUAW.formatted(),
            filterViewModel: filterViewModel,
            selectionStore: selectionStore,
            filterButtonLabel: "Filter",
            onClose: { showSheet = false },
            onOpenFilter: { showFilterPopup = true },
            icon: Image("uaw"),
            iconTint: Color(hex: "#2F2F2F"),
            iconStrokeColor: Color(hex: "#DCDEE1"),
            backgroundColor: Color(hex: "#2F2F2F")
        ) {
            StackedBarChartView(
                data: data,
                colorDomain: colorDomain,
                yLabel: "UAW",
                minHeight: 280
            )
            .layoutPriority(1)
        }.padding(16)
    }
}

private extension Array where Element: Hashable {
    func removingDuplicatesPreservingOrder(maxCount: Int? = nil) -> [Element] {
        var seen = Set<Element>()
        var result: [Element] = []
        for e in self where !seen.contains(e) {
            seen.insert(e)
            result.append(e)
            if let max = maxCount, result.count >= max { break }
        }
        return result
    }
}

