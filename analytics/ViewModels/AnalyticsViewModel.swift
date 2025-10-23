import Foundation
import SwiftUI

@Observable
final class AnalyticsViewModel {
    // Inputs
    var selectedAggregation: Aggregation = .sum
    
    var filterStartDate: Date?
    var filterEndDate: Date?
    
    private(set) var dappMetrics: [DAppMetric] = mockDAppMetrics()

    // Data
    private(set) var allData: [ViewMonthCategory] = mockViewMonthCategories()

    // Computed properties
    var filteredData: [ViewMonthCategory] {
        if let start = filterStartDate, let end = filterEndDate {
            return allData.filter { $0.date >= start && $0.date <= end }
        }
        return allData
    }
    
    var filteredDAppMetrics: [DAppMetric] {
        if let start = filterStartDate, let end = filterEndDate {
            return dappMetrics.filter { $0.date >= start && $0.date <= end }
        }
        return dappMetrics
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
    
    var aggregatedTradingVolume: Double {
        let values = filteredDAppMetrics.map { $0.tradingVolume ?? 0 }
        guard !values.isEmpty else { return 0 }

        switch selectedAggregation {
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
    
    var aggregatedUAW: Double {
        let values = filteredDAppMetrics.map { $0.dau ?? 0 }
        guard !values.isEmpty else { return 0 }
        switch selectedAggregation {
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
    
    var aggregatedTradingFees: Double {
        let values = filteredDAppMetrics.map { $0.tradingFees ?? 0 }
        guard !values.isEmpty else { return 0 }
        switch selectedAggregation {
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
