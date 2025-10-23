import Foundation
import SwiftUI

@Observable
final class AnalyticsViewModel {
    // Inputs
    var selectedAggregation: Aggregation = .sum
    var selectedRange: Range = .sixMonths

    // Data
    private(set) var allData: [ViewMonthCategory] = ViewMonthCategory.mockData()

    // Computed properties
    var filteredData: [ViewMonthCategory] {
        let calendar = Calendar.current
        let endDate = allData.map { $0.date }.max() ?? Date()
        let startDate: Date
        switch selectedRange {
        case .oneMonth: startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
        case .threeMonths: startDate = calendar.date(byAdding: .month, value: -3, to: endDate)!
        case .sixMonths: startDate = calendar.date(byAdding: .month, value: -6, to: endDate)!
        }
        return allData.filter { $0.date >= startDate && $0.date <= endDate }
    }

    // Aggregated metric depending on user selection
    var aggregatedValue: Int {
        let values = filteredData.map { $0.viewCount }
        guard !values.isEmpty else { return 0 }

        switch selectedAggregation {
        case .sum:
            return values.reduce(0, +)
        case .avg:
            return values.reduce(0, +) / values.count
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
