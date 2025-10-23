// Stores all mock/demo analytics data for the app.

import Foundation

// MARK: - Deterministic random helpers for stable mocks
private struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xDEADBEEF : seed }
    mutating func next() -> Double {
        // Xorshift64*
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        let result = state &* 2685821657736338717
        // Map to 0..1
        return Double(result % UInt64.max) / Double(UInt64.max)
    }
    mutating func normal(mean: Double = 0, std: Double = 1) -> Double {
        // Box-Muller transform
        let u1 = max(next(), 1e-9)
        let u2 = next()
        let z0 = sqrt(-2.0 * log(u1)) * cos(2 * .pi * u2)
        return mean + z0 * std
    }
}

private func seasonality(month m: Int, amplitude: Double = 0.1) -> Double {
    // Simple yearly sinus seasonality peaking mid-year
    let phase = 2 * Double.pi * (Double(m - 1) / 12.0)
    return 1.0 + amplitude * sin(phase)
}

// MARK: - DTOs shaped like Swagger schemas (no networking used)

struct DAppMetric: Identifiable, Codable {
    // date in ISO-8601 string in Swagger; we also expose Date for convenience
    let id = UUID()
    let date: Date
    let tvl: Double?
    let tradingVolume: Double?
    let tradingFees: Double?
    let capitalEfficiency: Double?
    let dau: Double? // aka UAW
    let txCount: Double? // number of transactions
    let uniqueTraders: Double? // distinct traders/wallets
}

struct AssetsDto: Codable {
    struct Asset: Identifiable, Codable, Hashable {
        let id: String
        let symbol: String
        let name: String
        let `protocol`: String
    }
    struct Pair: Identifiable, Codable, Hashable {
        let id: String
        let pair: String // e.g. "USDC/WGLMR"
        let name: String // e.g. "USD Coin/Wrapped GLMR"
        let `protocol`: String
    }
    let assets: [Asset]
    let pairs: [Pair]
}

// Asset-level metric rows matching AssetsMetricsDto.Metric
struct AssetMetric: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let assetId: String
    let pair: String?
    let symbol: String?
    let `protocol`: String
    let tvl: Double?
    let tradingVolume: Double?
    let tradingFees: Double?
    let capitalEfficiency: Double?
    let dau: Double?
    let txCount: Double?
    let uniqueTraders: Double?
}

// MARK: - Mock generators aligned to the DTOs

private func startOfCurrentMonth(_ cal: Calendar = .current, now: Date = Date()) -> Date {
    cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
}

func mockDAppMetrics(lastMonths: Int = 12, calendar cal: Calendar = .current) -> [DAppMetric] {
    let start = startOfCurrentMonth(cal)
    return (0..<lastMonths).reversed().compactMap { offset in
        guard let date = cal.date(byAdding: .month, value: -offset, to: start) else { return nil }
        let m = cal.component(.month, from: date)
        // Deterministic but varied
        let tvl = 20_000_000.0 + Double(m) * 750_000.0
        let volume = 5_000_000.0 + Double(m) * 350_000.0
        let seasonal = seasonality(month: m, amplitude: 0.12)
        let tvlAdj = tvl * seasonal
        let volumeAdj = volume * seasonal
        let feesAdj = volumeAdj * 0.0025
        let capEffAdj = volumeAdj / max(tvlAdj, 1)
        let uaw = 50_000.0 + Double(m) * 2_500.0
        let uawAdj = uaw * seasonal
        let tx = volumeAdj / 250.0 // assume avg trade size ~ $250
        let traders = uawAdj * 0.6 // 60% of DAU trade
        return DAppMetric(date: date, tvl: tvlAdj, tradingVolume: volumeAdj, tradingFees: feesAdj, capitalEfficiency: capEffAdj, dau: uawAdj, txCount: tx, uniqueTraders: traders)
    }
}

func mockAssetsDto() -> AssetsDto {
    let assets: [AssetsDto.Asset] = [
        .init(id: "1", symbol: "USDC", name: "USD Coin", protocol: "beamex-amm"),
        .init(id: "2", symbol: "WGLMR", name: "Wrapped GLMR", protocol: "beamex-amm")
    ]
    let pairs: [AssetsDto.Pair] = [
        .init(id: "12", pair: "USDC/WGLMR", name: "USD Coin/Wrapped GLMR", protocol: "beamswap-v3")
    ]
    return AssetsDto(assets: assets, pairs: pairs)
}

func mockAssetMetrics(lastMonths: Int = 12, calendar cal: Calendar = .current) -> [AssetMetric] {
    let dto = mockAssetsDto()
    let start = startOfCurrentMonth(cal)
    // Build metrics for each asset and pair
    var rows: [AssetMetric] = []
    for asset in dto.assets {
        for offset in (0..<lastMonths).reversed() {
            guard let date = cal.date(byAdding: .month, value: -offset, to: start) else { continue }
            let m = cal.component(.month, from: date)
            let tvl = 5_000_000.0 + Double(m) * 120_000.0
            let volume = 1_200_000.0 + Double(m) * 80_000.0
            let seasonal = seasonality(month: m, amplitude: 0.1)
            let tvlAdj = tvl * seasonal
            let volumeAdj = volume * seasonal
            let feesAdj = volumeAdj * 0.0018
            let capEffAdj = volumeAdj / max(tvlAdj, 1)
            let uaw = 10_000.0 + Double(m) * 600.0
            let uawAdj = uaw * seasonal
            let tx = volumeAdj / 220.0
            let traders = uawAdj * 0.55
            rows.append(AssetMetric(date: date, assetId: asset.id, pair: nil, symbol: asset.symbol, protocol: asset.protocol, tvl: tvlAdj, tradingVolume: volumeAdj, tradingFees: feesAdj, capitalEfficiency: capEffAdj, dau: uawAdj, txCount: tx, uniqueTraders: traders))
        }
    }
    for pair in dto.pairs {
        for offset in (0..<lastMonths).reversed() {
            guard let date = cal.date(byAdding: .month, value: -offset, to: start) else { continue }
            let m = cal.component(.month, from: date)
            let tvl = 7_500_000.0 + Double(m) * 150_000.0
            let volume = 2_200_000.0 + Double(m) * 140_000.0
            let seasonal = seasonality(month: m, amplitude: 0.14)
            let tvlAdj = tvl * seasonal
            let volumeAdj = volume * seasonal
            let feesAdj = volumeAdj * 0.0020
            let capEffAdj = volumeAdj / max(tvlAdj, 1)
            let uaw = 18_000.0 + Double(m) * 900.0
            let uawAdj = uaw * seasonal
            let tx = volumeAdj / 200.0
            let traders = uawAdj * 0.65
            rows.append(AssetMetric(date: date, assetId: pair.id, pair: pair.pair, symbol: nil, protocol: pair.protocol, tvl: tvlAdj, tradingVolume: volumeAdj, tradingFees: feesAdj, capitalEfficiency: capEffAdj, dau: uawAdj, txCount: tx, uniqueTraders: traders))
        }
    }
    return rows.sorted { $0.date < $1.date }
}

// MARK: - Daily mocks for fine-grained charts
func mockDAppMetricsDaily(lastDays: Int = 90, calendar cal: Calendar = .current, seed: UInt64 = 42) -> [DAppMetric] {
    let now = Date()
    var rng = SeededRandom(seed: seed)
    return (0..<lastDays).reversed().compactMap { d in
        guard let date = cal.date(byAdding: .day, value: -d, to: now) else { return nil }
        let m = cal.component(.month, from: date)
        let seasonal = seasonality(month: m, amplitude: 0.15)
        // Base levels
        let baseTVL = 22_000_000.0
        let baseVol = 1_100_000.0
        let baseUAW = 45_000.0
        // Trend + noise
        let trend = 1.0 + 0.0008 * Double(d) // slow upward trend
        let noise = 1.0 + rng.normal(mean: 0, std: 0.03)
        let tvl = max(1, baseTVL * seasonal * trend * noise)
        let volume = max(1, baseVol * seasonal * trend * (1.0 + rng.normal(std: 0.05)))
        let fees = volume * 0.0023
        let capEff = volume / tvl
        let uaw = max(1, baseUAW * seasonal * trend * (1.0 + rng.normal(std: 0.04)))
        let tx = volume / 240.0
        let traders = uaw * 0.58
        return DAppMetric(date: date, tvl: tvl, tradingVolume: volume, tradingFees: fees, capitalEfficiency: capEff, dau: uaw, txCount: tx, uniqueTraders: traders)
    }
}

// Generates simple monthly mock data with a date and a viewCount, matching AnalyticsViewModel's expectations.
func mockViewMonthCategories() -> [ViewMonthCategory] {
    let calendar = Calendar.current
    let now = Date()
    // Generate the first day of the last 12 months including current month
    let monthsBack = Array(0..<12).reversed()
    var items: [ViewMonthCategory] = []
    for offset in monthsBack {
        if let date = calendar.date(byAdding: .month, value: -offset, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now) {
            // Create a simple deterministic viewCount for consistency
            let monthIndex = calendar.component(.month, from: date)
            let viewCount = 1000 + monthIndex * 100
            // Expecting ViewMonthCategory to have init(date:category:viewCount:)
            items.append(ViewMonthCategory(date: date, category: ViewCategory(name: "All", colorName: "GraphBlue"), viewCount: viewCount))
        }
    }
    return items
}

// If you need additional mock data sets, add similar helpers here.

