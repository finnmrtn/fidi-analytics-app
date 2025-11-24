//
//  UAWSheet.swift
//  analytics
//
//  Created by Finn Garrels on 27.10.25.
//

import SwiftUI
import Charts

struct UAWPoint: Identifiable {
    let id: UUID
    let date: Date
    let value: Double
    let project: String
}

struct UAWSheet: View {
    var viewModel: AnalyticsViewModel
    @Binding var showSheet: Bool
    var filterViewModel: TimeFilterViewModel

    @State private var showFilterPopup: Bool = false

    var body: some View {
        // Use real directory names for projects via dappId lookup
        let nameMap = nameByDappId()

        // Map metrics -> (date, value, projectName)
        let points = viewModel.filteredDAppMetrics.map { metric -> (date: Date, value: Double, project: String) in
            let name = nameMap[metric.dappId] ?? "Project"
            return (date: metric.date, value: Double(metric.dau ?? 0), project: name)
        }

        // Compute total UAW per project across the filtered range to find top 9
        let totalsByProject: [String: Double] = points.reduce(into: [:]) { dict, item in
            dict[item.project, default: 0] += item.value
        }
        // Preserve ranking order for color assignment (descending by total)
        let rankedTop: [String] = totalsByProject.sorted { $0.value > $1.value }.prefix(9).map { $0.key }
        let rankedCategories: [String] = rankedTop + ["Other"]

        // Define palette per requested ranking mapping
        // #1 -> GraphColor2
        // #2 -> GraphColor6
        // #3 -> GraphColor5
        // #4 -> GraphColor7
        // #5 -> GraphColor4
        // #6 -> GraphColor3
        // #7 -> GraphColor1
        // #8 -> GraphColor8
        // #9 -> GraphColor9
        // #10 Other -> GraphColor10
        let palette: [Color] = [
            Color("GraphColor2"),
            Color("GraphColor6"),
            Color("GraphColor5"),
            Color("GraphColor7"),
            Color("GraphColor4"),
            Color("GraphColor3"),
            Color("GraphColor1"),
            Color("GraphColor8"),
            Color("GraphColor9"),
            Color("GraphColor10")
        ]

        // Build domain and range arrays for Charts (ordered mapping)
        let colorDomain: [String] = rankedTop + ["Other"]
        let colorRange: [Color] = [
            Color("GraphColor2"),
            Color("GraphColor6"),
            Color("GraphColor5"),
            Color("GraphColor7"),
            Color("GraphColor4"),
            Color("GraphColor3"),
            Color("GraphColor1"),
            Color("GraphColor8"),
            Color("GraphColor9"),
            Color("GraphColor10")
        ]

        // Collapse non-top projects into "Other" and pre-aggregate by (date, project)
        let aggregatedByDateAndProject: [Date: [String: Double]] = points.reduce(into: [:]) { result, item in
            let category = rankedTop.contains(item.project) ? item.project : "Other"
            var inner = result[item.date] ?? [:]
            inner[category, default: 0] += item.value
            result[item.date] = inner
        }

        // Flatten back into UAWPoint rows for the chart
        let data: [UAWPoint] = aggregatedByDateAndProject.flatMap { (date, buckets) in
            buckets.map { (project, total) in
                UAWPoint(id: UUID(), date: date, value: total, project: project)
            }
        }.sorted { lhs, rhs in
            if lhs.date == rhs.date { return lhs.project < rhs.project }
            return lhs.date < rhs.date
        }
        
        MetricSheetTemplate(
            title: "Unique Active Wallets",
            metric: "Unique Active Wallets",
            metricValue: viewModel.aggregatedUAW.formatted(),
            onClose: { showSheet = false },
            onOpenFilter: { showFilterPopup = true },
            icon: Image("uaw")
        ) {
            GeometryReader { proxy in
                let availableHeight = max(proxy.size.height, 220)
                Chart(data) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .month),
                        y: .value("UAW", point.value)
                    )
                    .foregroundStyle(by: .value("Project", point.project))
                }
                .chartLegend(.visible)
                .chartForegroundStyleScale(domain: colorDomain, range: colorRange)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks {
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
                .frame(height: availableHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(minHeight: 280)
            .layoutPriority(1)
        }
        .padding(16)
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
