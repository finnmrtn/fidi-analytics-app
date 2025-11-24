import Foundation

public enum ChartAggregation {
    /// Aggregates raw (date, value, project) tuples into Top-N categories plus an "Other" bucket per date,
    /// returning StackedBarChartPoint data and a colorDomain in ranked order (Top-N + "Other").
    /// - Parameters:
    ///   - points: Raw tuples representing (date, value, project)
    ///   - topCount: Number of top categories to keep before collapsing the rest into "Other". Default: 9
    /// - Returns: (data: [StackedBarChartPoint], colorDomain: [String])
    public static func aggregateTopNWithOther(
        from points: [(date: Date, value: Double, project: String)],
        topCount: Int = 9
    ) -> (data: [StackedBarChartPoint], colorDomain: [String]) {
        // Compute total per project
        let totalsByProject: [String: Double] = points.reduce(into: [:]) { dict, item in
            dict[item.project, default: 0] += item.value
        }
        // Top-N ranked by total desc
        let rankedTop: [String] = totalsByProject
            .sorted { $0.value > $1.value }
            .prefix(topCount)
            .map { $0.key }

        // Domain for colors (Top-N + Other)
        let colorDomain: [String] = rankedTop + ["Other"]

        // Aggregate per (date, category) where non-top collapse into "Other"
        let aggregatedByDateAndProject: [Date: [String: Double]] = points.reduce(into: [:]) { result, item in
            let category = rankedTop.contains(item.project) ? item.project : "Other"
            var inner = result[item.date] ?? [:]
            inner[category, default: 0] += item.value
            result[item.date] = inner
        }

        // Flatten back into points and sort by date then category
        let data: [StackedBarChartPoint] = aggregatedByDateAndProject.flatMap { (date, buckets) in
            buckets.map { (project, total) in
                StackedBarChartPoint(date: date, value: total, category: project)
            }
        }
        .sorted { lhs, rhs in
            if lhs.date == rhs.date { return lhs.category < rhs.category }
            return lhs.date < rhs.date
        }

        return (data, colorDomain)
    }
}
