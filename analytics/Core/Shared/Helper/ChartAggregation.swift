import Foundation

enum ChartAggregation {
    private static let bucketer = TimeBucketer()

    public static func aggregateTopNWithOther(
        from points: [(date: Date, value: Double, project: String)],
        topCount: Int,
        bucket: TimeBucket?,
        calendar: Calendar
    ) -> (data: [StackedBarChartPoint], colorDomain: [String]) {
        // Return empty when no points
        guard !points.isEmpty else { return (data: [], colorDomain: []) }

        // Helper to compute bucket start
        func bucketStart(_ d: Date) -> Date {
            guard let bucket else { return d }
            return bucketer.bucketStart(for: d, bucket: bucket, calendar: calendar)
        }

        // 1) Sum per (bucketStart, project)
        var byBucketProject: [Date: [String: Double]] = [:]
        for p in points {
            let b = bucketStart(p.date)
            var perProject = byBucketProject[b] ?? [:]
            perProject[p.project, default: 0] += p.value
            byBucketProject[b] = perProject
        }

        // 2) Global totals to select stable Top-9
        var globalTotals: [String: Double] = [:]
        for (_, perProject) in byBucketProject {
            for (project, v) in perProject {
                globalTotals[project, default: 0] += v
            }
        }
        let orderedTop9: [String] = globalTotals
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .prefix(9)
            .map { $0.key }
        let topSet = Set(orderedTop9)

        // 3) Emit exactly 10 segments per bucket: up to 9 Top projects present + 1 Other
        var data: [StackedBarChartPoint] = []
        let sortedBuckets = byBucketProject.keys.sorted()
        for b in sortedBuckets {
            let perProject = byBucketProject[b] ?? [:]
            var bucketPoints: [StackedBarChartPoint] = []

            // Add Top-9 (only those with value > 0 in this bucket), in stable order
            for project in orderedTop9 {
                if let v = perProject[project], v > 0 {
                    bucketPoints.append(StackedBarChartPoint(date: b, value: v, category: project))
                }
            }

            // Sum remaining projects into Other
            var otherSum = 0.0
            for (project, v) in perProject where !topSet.contains(project) {
                otherSum += v
            }
            // Always include exactly one Other segment per bucket (even if 0),
            // to keep a consistent 10-segment structure visually where possible.
            // If you prefer to hide zero, set the condition to (otherSum > 0).
            bucketPoints.append(StackedBarChartPoint(date: b, value: otherSum, category: "Other"))

            // Ensure at most 10 segments (Top up to 9 + Other)
            // If fewer than 9 Top projects have data in this bucket, we still keep Other as the 10th.
            data.append(contentsOf: bucketPoints)
        }

        // 4) Color domain: stable Top-9 + Other
        var colorDomain = orderedTop9
        colorDomain.append("Other")
        return (data: data, colorDomain: colorDomain)
    }
}

