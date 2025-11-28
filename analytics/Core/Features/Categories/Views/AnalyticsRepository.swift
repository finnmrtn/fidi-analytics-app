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
        // Use deterministic example rollups to keep UI stable for now
        return mockExampleCategoryRollups(for: network)
    }

    func fetchTopProjects(in category: CategoryKind, network: Network, limit: Int, weights: CategoriesViewModel.RankingWeights, start: Date?, end: Date?) async throws -> [TopProjectDisplay] {
        // Use example top projects derived from example rollups
        return mockExampleTopProjects(in: category, for: network, limit: limit)
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
