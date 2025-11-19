import Foundation

struct StackedSeriesPoint {
    let value: Double
    let category: String
}

struct StackedSeriesPart {
    let points: [StackedSeriesPoint]
    let name: String
}
