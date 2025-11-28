import Foundation

struct StackedBarChartPoint {
    let date: Date
    let name: String
    let value: Double
}

enum ChartAggregation {
    private static let bucketer = TimeBucketer()

    public static func aggregateTopNWithOther(
        from points: [(date: Date, value: Double, project: String)],
        topCount: Int,
        bucket: TimeBucket?,
        calendar: Calendar
    ) -> (data: [StackedBarChartPoint], colorDomain: [String]) {
        // Early exit if no points
        guard !points.isEmpty else {
            return ([], [])
        }
        
        // Determine the time bucket function if bucket is provided
        let bucketFunc: ((Date) -> Date)?
        if let bucket = bucket {
            bucketFunc = { date in
                bucketer.bucket(for: date, bucket: bucket, calendar: calendar)
            }
        } else {
            bucketFunc = nil
        }
        
        // Aggregate values by project
        var totalPerProject: [String: Double] = [:]
        for point in points {
            totalPerProject[point.project, default: 0] += point.value
        }
        
        // Determine top N projects
        let sortedProjects = totalPerProject.sorted(by: { $0.value > $1.value }).map { $0.key }
        let topProjects = Set(sortedProjects.prefix(topCount))
        
        // Prepare aggregated data dictionary: [bucketedDate: [projectName: value]]
        var aggregatedData: [Date: [String: Double]] = [:]
        
        for point in points {
            let bucketedDate = bucketFunc?(point.date) ?? point.date
            var projectName = point.project
            if !topProjects.contains(projectName) {
                projectName = "Other"
            }
            if aggregatedData[bucketedDate] == nil {
                aggregatedData[bucketedDate] = [:]
            }
            aggregatedData[bucketedDate]![projectName, default: 0] += point.value
        }
        
        // Ensure "Other" is included if needed
        var colorDomain = Array(topProjects)
        if totalPerProject.keys.contains(where: { !topProjects.contains($0) }) {
            colorDomain.append("Other")
        }
        
        // Sort dates ascending
        let sortedDates = aggregatedData.keys.sorted()
        
        // Build final data points
        var result: [StackedBarChartPoint] = []
        for date in sortedDates {
            let projectValues = aggregatedData[date] ?? [:]
            for project in colorDomain {
                let value = projectValues[project] ?? 0
                result.append(StackedBarChartPoint(date: date, name: project, value: value))
            }
        }
        
        return (result, colorDomain)
    }
}
