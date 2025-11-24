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
    
    // Top-10 Gas Fees rows joined with directory names (DEV mock)
    var top10FeesRows: [DAppDisplayRow] {
        // 1) Start from filtered metrics (already respects date filter)
        let rows = filteredDAppMetrics
        guard !rows.isEmpty else { return [] }
        // 2) Group by dappId
        let grouped = Dictionary(grouping: rows, by: { $0.dappId })
        // 3) Aggregate per group according to selectedAggregation
        func aggregate(_ values: [Double]) -> Double {
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
        let directory = mockDirectoryItems()
        let nameById = Dictionary(uniqueKeysWithValues: directory.map { ($0.id, $0.name) })
        // 4) Build display rows with aggregated fees
        let display: [DAppDisplayRow] = grouped.map { (dappId, metrics) in
            let fees = aggregate(metrics.map { $0.tradingFees ?? 0 })
            return DAppDisplayRow(id: dappId, name: nameById[dappId] ?? "Project", tradingFees: fees)
        }
        // 5) Sort and take top 10
        return display.sorted { $0.tradingFees > $1.tradingFees }.prefix(10).map { $0 }
    }

    // Aggregate for the sheet header (sum over the Top-10 fees)
    var aggregatedTop10TradingFees: Double {
        top10FeesRows.reduce(0) { $0 + $1.tradingFees }
    }
}

