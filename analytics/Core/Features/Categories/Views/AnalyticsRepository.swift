import Foundation
import SwiftUI

// Central protocol the ViewModels depend on. Later, add a real API-backed implementation.
protocol AnalyticsRepository {
    // Categories / Explore
    func fetchCategoryRollups(network: Network, start: Date?, end: Date?, aggregation: Aggregation) async throws -> [CategoryRollup]
    func fetchTopProjects(in category: CategoryKind, network: Network, limit: Int, weights: CategoriesViewModel.RankingWeights, start: Date?, end: Date?) async throws -> [TopProjectDisplay]

    // Time series for dashboard
    func fetchUAWSeries(timeframe: Timeframe) async throws -> [(Date, Double)]
    func fetchTransactionsSeries(timeframe: Timeframe) async throws -> [(Date, Double)]
    func fetchTxFeesSeries(timeframe: Timeframe) async throws -> [(Date, Double)]
    func fetchGasFeesSeries(timeframe: Timeframe) async throws -> [(Date, Double)]
    func fetchAssetPriceSeries(timeframe: Timeframe) async throws -> [(Date, Double)]

    // Raw DApp metrics if needed by other screens
    func fetchDAppMetricsDaily(lastDays: Int) async throws -> [DAppMetric]
    func fetchViewMonthCategories() async throws -> [ViewMonthCategory]
}

// Default in-app mock implementation using existing mock generators.
final class MockAnalyticsRepository: AnalyticsRepository {
    func fetchCategoryRollups(network: Network, start: Date?, end: Date?, aggregation: Aggregation) async throws -> [CategoryRollup] {
        // Build deterministic example rollups without external helpers
        let baseKinds: [CategoryKind] = [.defi, .nfts, .gaming, .lending]
        let rollups: [CategoryRollup] = baseKinds.enumerated().map { (idx, kind) in
            // We don't have a shared CategoryRollup type anymore in mocks; synthesize a lightweight DTO for repository consumers if needed.
            // For now, map into view model's local rollup in CategoriesViewModel, so return empty here.
            // If a shared CategoryRollup type exists in your project, replace this with actual construction.
            fatalError("CategoryRollup type is not defined in mocks. Define a shared CategoryRollup model or adjust repository signature.")
        }
        return rollups
    }

    func fetchTopProjects(in category: CategoryKind, network: Network, limit: Int, weights: CategoriesViewModel.RankingWeights, start: Date?, end: Date?) async throws -> [TopProjectDisplay] {
        // Build deterministic example top projects without external helpers
        #if canImport(SwiftUI)
        var items: [TopProjectDisplay] = []
        for i in 1...max(1, limit) {
            let name = "\(category.rawValue) Project \(i)"
            let id = "proj_\(i)"
            let transactions = Double(5_000 * i)
            let uaw = Double(1_000 * i)
            // Assuming TopProjectDisplay is defined somewhere shared. If not, adjust this repository to return a local type instead.
            items.append(TopProjectDisplay(id: id, name: name, category: LocalCategoryKindShim(rawValue: category.rawValue) ?? .other, network: LocalNetworkShim(rawValue: network.rawValue) ?? .moonbeam, transactions: transactions, uaw: uaw))
        }
        return items
        #else
        fatalError("TopProjectDisplay type not available. Define it or adjust repository return type.")
        #endif
    }

    func fetchUAWSeries(timeframe: Timeframe) async throws -> [(Date, Double)] {
        return mockUAWSeries(timeframe: timeframe).map { ($0.date, $0.value) }
    }

    func fetchTransactionsSeries(timeframe: Timeframe) async throws -> [(Date, Double)] {
        return mockTransactionsSeries(timeframe: timeframe).map { ($0.date, $0.value) }
    }

    func fetchTxFeesSeries(timeframe: Timeframe) async throws -> [(Date, Double)] {
        return mockTransactionFeesSeries(timeframe: timeframe).map { ($0.date, $0.value) }
    }

    func fetchGasFeesSeries(timeframe: Timeframe) async throws -> [(Date, Double)] {
        return mockGasFeesSeries(timeframe: timeframe).map { ($0.date, $0.value) }
    }

    func fetchAssetPriceSeries(timeframe: Timeframe) async throws -> [(Date, Double)] {
        return assetPriceSeries(timeframe: timeframe)
    }

    func fetchDAppMetricsDaily(lastDays: Int) async throws -> [DAppMetric] {
        return mockDAppMetricsDaily(lastDays: lastDays)
    }

    func fetchViewMonthCategories() async throws -> [ViewMonthCategory] {
        return mockViewMonthCategories()
    }
}
