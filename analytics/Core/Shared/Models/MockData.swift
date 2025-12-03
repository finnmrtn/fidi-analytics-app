import Foundation
import Darwin

public enum CategoryKind: String, CaseIterable, Codable, Identifiable {
    case overview = "Overview"
    case gaming = "Gaming"
    case nfts = "NFTs"
    case wallets = "Wallets"
    case bridges = "Bridges"
    case lending = "Lending"
    case social = "Social"
    case dex = "DEX"
    case dao = "DAO"
    case defi = "DeFi"
    case depin = "DePin"
    case infrastructure = "Infrastructure"
    case other = "Other"
    public var id: String { rawValue }
}

public enum Timeframe {
    case oneDay
    case oneWeek
    case oneMonth
    case oneYear
    case ytd
    case all
}

private func timeframeRange(_ timeframe: Timeframe, calendar cal: Calendar = .current, now: Date = Date()) -> (start: Date?, end: Date) {
    let end = now
    switch timeframe {
    case .oneDay:
        let start = cal.date(byAdding: .day, value: -1, to: end)
        return (start, end)
    case .oneWeek:
        let start = cal.date(byAdding: .day, value: -7, to: end)
        return (start, end)
    case .oneMonth:
        let start = cal.date(byAdding: .month, value: -1, to: end)
        return (start, end)
    case .oneYear:
        let start = cal.date(byAdding: .year, value: -1, to: end)
        return (start, end)
    case .ytd:
        let comps = cal.dateComponents([.year], from: end)
        let startOfYear = cal.date(from: DateComponents(year: comps.year))
        return (startOfYear, end)
    case .all:
        return (nil, end)
    }
}

private struct DAppMetricRow { let date: Date }

private func fetchDAppMetricsRange(start: Date?, end: Date, calendar cal: Calendar = .current) -> [DAppMetricRow] {
    // Produce timestamps between start and end with a reasonable cadence depending on span
    let endDate = end
    let startDate: Date = start ?? cal.date(byAdding: .year, value: -2, to: endDate)!

    let totalSeconds = endDate.timeIntervalSince(startDate)
    let day: TimeInterval = 24 * 60 * 60

    let stepSeconds: TimeInterval
    if totalSeconds <= day {               // up to 1 day
        stepSeconds = 10 * 60             // 10 minutes
    } else if totalSeconds <= 7 * day {    // up to 1 week
        stepSeconds = 2 * 60 * 60         // 2 hours
    } else if totalSeconds <= 35 * day {   // up to ~1 month
        stepSeconds = day                  // 1 day
    } else {                               // longer ranges
        stepSeconds = 7 * day              // 1 week
    }

    var dates: [DAppMetricRow] = []
    var t = startDate
    while t <= endDate {
        dates.append(DAppMetricRow(date: t))
        t = t.addingTimeInterval(stepSeconds)
    }
    if dates.last?.date != endDate { dates.append(DAppMetricRow(date: endDate)) }
    return dates
}

private func synthesizedAssetPriceSeries(
    dates: [Date],
    calendar cal: Calendar,
    seed: UInt64,
    startPrice: Double,
    dailyDrift: Double,
    dailyVolatility: Double,
    seasonalityAmplitude: Double,
    minPrice: Double,
    maxPrice: Double
) -> [(Date, Double)] {
    // Simple pseudo-random GBM-like generator seeded deterministically
    var result: [(Date, Double)] = []
    guard !dates.isEmpty else { return result }
    // Deterministic LCG
    var state = seed
    func rand() -> Double {
        state = 6364136223846793005 &* state &+ 1
        // Map to (0,1)
        let x = Double(state & 0xFFFFFFFFFFFF) / Double(0xFFFFFFFFFFFF)
        return x
    }
    var price = max(minPrice, min(maxPrice, startPrice))
    let dayInSeconds: Double = 24 * 60 * 60
    var lastDate = dates.first!
    for d in dates {
        let dt = max(1.0, d.timeIntervalSince(lastDate) / dayInSeconds)
        lastDate = d
        // Drift and volatility scaled by dt
        let driftTerm = dailyDrift * dt
        let volTerm = dailyVolatility * sqrt(dt)
        // Box-Muller for normal
        let u1 = max(1e-12, rand())
        let u2 = max(1e-12, rand())
        let z = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        // Seasonality (annual sine)
        let dayOfYear = Double(cal.ordinality(of: .day, in: .year, for: d) ?? 1)
        let seas = seasonalityAmplitude * sin(2.0 * .pi * dayOfYear / 365.0)
        // Geometric Brownian Motion step in log space
        let growth = exp((driftTerm - 0.5 * volTerm * volTerm) + volTerm * z + seas * 0.01)
        price = price * growth
        price = max(minPrice, min(maxPrice, price))
        result.append((d, price))
    }
    return result
}

func assetPriceSeries(timeframe: Timeframe, calendar cal: Calendar = .current, now: Date = Date(), minPrice: Double = 0.01, maxPrice: Double = 0.5) -> [(date: Date, price: Double)] {
    // Compute start/end for requested timeframe, with ALL forced to 2 years
    let startEnd: (start: Date?, end: Date)
    switch timeframe {
    case .oneDay:
        startEnd = timeframeRange(.oneDay, calendar: cal, now: now)
    case .oneWeek:
        startEnd = timeframeRange(.oneWeek, calendar: cal, now: now)
    case .oneMonth:
        startEnd = timeframeRange(.oneMonth, calendar: cal, now: now)
    case .oneYear:
        startEnd = timeframeRange(.oneYear, calendar: cal, now: now)
    case .ytd:
        startEnd = timeframeRange(.ytd, calendar: cal, now: now)
    case .all:
        let end = now
        let start = cal.date(byAdding: .year, value: -2, to: end)
        startEnd = (start, end)
    }

    // Use range fetcher for timestamps
    let rows = fetchDAppMetricsRange(start: startEnd.start, end: startEnd.end, calendar: cal)
    let dates = rows.map { $0.date }

    // Tune synthesis parameters by granularity/window to feel more realistic
    let (startPrice, drift, vol, seasAmp): (Double, Double, Double, Double)
    switch timeframe {
    case .oneDay:
        // Short window: more wiggle, tiny drift
        (startPrice, drift, vol, seasAmp) = (0.08, 0.0002, 0.10, 0.10)
    case .oneWeek:
        (startPrice, drift, vol, seasAmp) = (0.08, 0.0004, 0.06, 0.10)
    case .oneMonth:
        (startPrice, drift, vol, seasAmp) = (0.08, 0.0006, 0.04, 0.10)
    case .ytd:
        (startPrice, drift, vol, seasAmp) = (0.08, 0.0007, 0.035, 0.12)
    case .oneYear:
        (startPrice, drift, vol, seasAmp) = (0.08, 0.0007, 0.03, 0.12)
    case .all:
        (startPrice, drift, vol, seasAmp) = (0.08, 0.0008, 0.025, 0.12)
    }

    // Generate base GBM series
    var series = synthesizedAssetPriceSeries(
        dates: dates,
        calendar: cal,
        seed: 20241128,
        startPrice: max(minPrice, min(maxPrice, startPrice)),
        dailyDrift: drift,
        dailyVolatility: vol,
        seasonalityAmplitude: seasAmp,
        minPrice: minPrice,
        maxPrice: maxPrice
    )

    // Apply slight mean reversion around a gentle moving anchor to avoid runaway
    if !series.isEmpty {
        // Compute a slow EMA anchor and blend a little toward it
        let alpha = 0.02 // slow EMA
        var ema = series.first!.1
        for i in 0..<series.count {
            let p = series[i].1
            ema = alpha * p + (1 - alpha) * ema
            // Blend 5% toward EMA to reduce unrealistic drift
            let blended = 0.95 * p + 0.05 * ema
            series[i].1 = max(minPrice, min(maxPrice, blended))
        }
    }

    // Add tiny intraday wave for short windows so minutely/hourly charts feel alive
    if timeframe == .oneDay || timeframe == .oneWeek {
        for i in 0..<series.count {
            let d = series[i].0
            let hour = cal.component(.hour, from: d)
            let minute = cal.component(.minute, from: d)
            let intraday = 1.0 + 0.004 * sin(Double(hour) / 24.0 * 2 * .pi)
            let micro = 1.0 + 0.002 * sin(Double(minute) / 60.0 * 2 * .pi)
            let p = series[i].1 * intraday * micro
            series[i].1 = max(minPrice, min(maxPrice, p))
        }
    }

    return series.sorted { $0.0 < $1.0 }
}


// MARK: - Directory models and helpers (moved here to centralize mocks)
public struct DirectoryItem: Hashable, Identifiable {
    public let id: String
    public let name: String
}

public func mockDirectoryItems() -> [DirectoryItem] {
    return [
        DirectoryItem(id: "dapp.amm.moon", name: "MoonSwap"),
        DirectoryItem(id: "dapp.bridge.beam", name: "BeamBridge"),
        DirectoryItem(id: "dapp.stake.stellar", name: "StellarStake"),
        DirectoryItem(id: "dapp.lend.orbit", name: "OrbitLend"),
        DirectoryItem(id: "dapp.vault.rock", name: "RockVault"),
        DirectoryItem(id: "dapp.nft.zk", name: "zkNFTHub"),
        DirectoryItem(id: "dapp.pay.zero", name: "ZeroGasPay"),
        DirectoryItem(id: "dapp.dex.mantle", name: "MantleDEX"),
        // Additional items to create real 'Others' volume
        DirectoryItem(id: "dapp.social.echo", name: "EchoSocial"),
        DirectoryItem(id: "dapp.dao.orion", name: "OrionDAO"),
        DirectoryItem(id: "dapp.defi.river", name: "RiverDeFi"),
        DirectoryItem(id: "dapp.wallet.lyra", name: "LyraWallet"),
        DirectoryItem(id: "dapp.gaming.nebula", name: "NebulaGame"),
        DirectoryItem(id: "dapp.bridge.nova", name: "NovaBridge"),
        DirectoryItem(id: "dapp.lend.zen", name: "ZenLend"),
        DirectoryItem(id: "dapp.nft.spectrum", name: "SpectrumNFT")
    ]
}

public func nameByDappId() -> [String: String] {
    let items = mockDirectoryItems()
    return Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.name) })
}

// MARK: - Analytics models used by the ViewModel
public struct DAppMetric: Hashable {
    public let date: Date
    public let dappId: String
    public let tradingVolume: Double?
    public let tradingFees: Double?
    public let dau: Double? // Daily Active Users (UAW)
}

public struct UAWPoint: Hashable { public let date: Date; public let value: Double }
public struct TransactionsPoint: Hashable { public let date: Date; public let value: Double }
public struct TransactionFeesPoint: Hashable { public let date: Date; public let value: Double }
public struct GasFeesPoint: Hashable { public let date: Date; public let value: Double }

public struct ViewMonthCategory: Hashable {
    public let date: Date
    public let viewCount: Int
}

public struct DAppDisplayRow: Hashable, Identifiable {
    public let id: String
    public let name: String
    public let tradingFees: Double
}

// MARK: - Mock generators for AnalyticsViewModel
public func mockDAppMetricsDaily(lastDays: Int) -> [DAppMetric] {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    let dapps = mockDirectoryItems().map { $0.id }
    var result: [DAppMetric] = []
    var state: UInt64 = 0xDEADBEEFCAFEBABE
    func rand() -> Double {
        state = 6364136223846793005 &* state &+ 1
        return Double(state & 0xFFFFFFFFFFFF) / Double(0xFFFFFFFFFFFF)
    }
    for dayOffset in (0..<lastDays).reversed() {
        let date = cal.date(byAdding: .day, value: -dayOffset, to: today)!
        for (idx, dapp) in dapps.enumerated() {
            let base = Double((idx + dayOffset) % 13) / 13.0
            // Per-dapp deterministic multiplier (1.0x ... ~2.2x)
            let dappHash = UInt64(abs(dapp.hashValue)) & 0xFFFF
            let dappMultiplier = 1.0 + 1.2 * (Double(dappHash) / Double(0xFFFF))

            // Volume with wider spread and some structure
            let vol = 8_000.0
                + 80_000.0 * (0.45 * base + 0.55 * rand())
                + 20_000.0 * sin(Double((idx * 13 + dayOffset) % 90) / 90.0 * 2.0 * .pi)

            // Non-linear fee rate with per-dapp bias and slight time drift
            let baseFeeRate = 0.0012 + 0.0009 * base
            let perDappBias = 0.0004 * (Double((idx * 97) % 100) / 100.0 - 0.5) // ~±0.0002
            let timeWobble = 0.00025 * sin(Double(dayOffset) / 17.0 * 2.0 * .pi)
            let feeRate = max(0.0003, baseFeeRate + perDappBias + timeWobble)

            // Apply non-linear scaling and multiplier
            let fees = (vol * feeRate * (0.75 + 0.25 * (vol / 100_000.0))) * dappMultiplier

            let users = 500.0 + 2500.0 * (base * 0.7 + rand() * 0.3)
            result.append(DAppMetric(date: date, dappId: dapp, tradingVolume: vol, tradingFees: fees, dau: users))
        }
    }
    return result.sorted { $0.date < $1.date }
}

public func mockUAWSeries(timeframe: Timeframe, calendar cal: Calendar = .current, now: Date = Date()) -> [UAWPoint] {
    let (start, end) = {
        switch timeframe {
        case .oneDay: return timeframeRange(.oneDay, calendar: cal, now: now)
        case .oneWeek: return timeframeRange(.oneWeek, calendar: cal, now: now)
        case .oneMonth: return timeframeRange(.oneMonth, calendar: cal, now: now)
        case .oneYear: return timeframeRange(.oneYear, calendar: cal, now: now)
        case .ytd: return timeframeRange(.ytd, calendar: cal, now: now)
        case .all: return timeframeRange(.all, calendar: cal, now: now)
        }
    }()
    let rows = fetchDAppMetricsRange(start: start, end: end, calendar: cal)
    let datesAll = rows.map { $0.date }
    let N = targetCount(for: timeframe)
    let idx = evenStrideIndices(total: datesAll.count, targetCount: N)
    let dates = idx.map { datesAll[$0] }

    var state: UInt64 = 0xA11CE0A1
    func rand() -> Double { state = 6364136223846793005 &* state &+ 1; return Double(state & 0xFFFFFFFFFFFF) / Double(0xFFFFFFFFFFFF) }
    // Scale by timeframe
    let base: (Double, Double)
    switch timeframe {
    case .oneDay: base = (2_000, 3_500)
    case .oneWeek: base = (3_000, 5_000)
    case .oneMonth: base = (4_000, 7_000)
    case .oneYear: base = (5_000, 9_000)
    case .ytd: base = (5_000, 9_000)
    case .all: base = (4_000, 8_000)
    }
    return dates.map { d in
        let v = base.0 + (base.1 - base.0) * (0.6 * rand() + 0.4)
        return UAWPoint(date: d, value: v)
    }
}

public func mockTransactionsSeries(timeframe: Timeframe, calendar cal: Calendar = .current, now: Date = Date()) -> [TransactionsPoint] {
    let (start, end) = {
        switch timeframe {
        case .oneDay: return timeframeRange(.oneDay, calendar: cal, now: now)
        case .oneWeek: return timeframeRange(.oneWeek, calendar: cal, now: now)
        case .oneMonth: return timeframeRange(.oneMonth, calendar: cal, now: now)
        case .oneYear: return timeframeRange(.oneYear, calendar: cal, now: now)
        case .ytd: return timeframeRange(.ytd, calendar: cal, now: now)
        case .all: return timeframeRange(.all, calendar: cal, now: now)
        }
    }()
    let rows = fetchDAppMetricsRange(start: start, end: end, calendar: cal)
    let datesAll = rows.map { $0.date }
    let N = targetCount(for: timeframe)
    let idx = evenStrideIndices(total: datesAll.count, targetCount: N)
    let dates = idx.map { datesAll[$0] }

    var state: UInt64 = 0xA11CE7A1
    func rand() -> Double { state = 6364136223846793005 &* state &+ 1; return Double(state & 0xFFFFFFFFFFFF) / Double(0xFFFFFFFFFFFF) }
    let base: (Double, Double)
    switch timeframe {
    case .oneDay: base = (20_000, 40_000)
    case .oneWeek: base = (30_000, 60_000)
    case .oneMonth: base = (40_000, 90_000)
    case .oneYear: base = (50_000, 110_000)
    case .ytd: base = (50_000, 110_000)
    case .all: base = (40_000, 100_000)
    }
    return dates.map { d in
        let v = base.0 + (base.1 - base.0) * (0.6 * rand() + 0.4)
        return TransactionsPoint(date: d, value: v)
    }
}

public func mockTransactionFeesSeries(timeframe: Timeframe, calendar cal: Calendar = .current, now: Date = Date()) -> [TransactionFeesPoint] {
    let (start, end) = {
        switch timeframe {
        case .oneDay: return timeframeRange(.oneDay, calendar: cal, now: now)
        case .oneWeek: return timeframeRange(.oneWeek, calendar: cal, now: now)
        case .oneMonth: return timeframeRange(.oneMonth, calendar: cal, now: now)
        case .oneYear: return timeframeRange(.oneYear, calendar: cal, now: now)
        case .ytd: return timeframeRange(.ytd, calendar: cal, now: now)
        case .all: return timeframeRange(.all, calendar: cal, now: now)
        }
    }()
    let rows = fetchDAppMetricsRange(start: start, end: end, calendar: cal)
    let datesAll = rows.map { $0.date }
    let N = targetCount(for: timeframe)
    let idx = evenStrideIndices(total: datesAll.count, targetCount: N)
    let dates = idx.map { datesAll[$0] }

    var state: UInt64 = 0xA11CEFEE
    func rand() -> Double { state = 6364136223846793005 &* state &+ 1; return Double(state & 0xFFFFFFFFFFFF) / Double(0xFFFFFFFFFFFF) }
    let base: (Double, Double)
    switch timeframe {
    case .oneDay: base = (8_000, 15_000)
    case .oneWeek: base = (12_000, 22_000)
    case .oneMonth: base = (15_000, 30_000)
    case .oneYear: base = (18_000, 36_000)
    case .ytd: base = (18_000, 36_000)
    case .all: base = (15_000, 32_000)
    }
    return dates.map { d in
        let v = base.0 + (base.1 - base.0) * (0.6 * rand() + 0.4)
        return TransactionFeesPoint(date: d, value: v)
    }
}

public func mockGasFeesSeries(timeframe: Timeframe, calendar cal: Calendar = .current, now: Date = Date()) -> [GasFeesPoint] {
    let (start, end) = {
        switch timeframe {
        case .oneDay: return timeframeRange(.oneDay, calendar: cal, now: now)
        case .oneWeek: return timeframeRange(.oneWeek, calendar: cal, now: now)
        case .oneMonth: return timeframeRange(.oneMonth, calendar: cal, now: now)
        case .oneYear: return timeframeRange(.oneYear, calendar: cal, now: now)
        case .ytd: return timeframeRange(.ytd, calendar: cal, now: now)
        case .all: return timeframeRange(.all, calendar: cal, now: now)
        }
    }()
    let rows = fetchDAppMetricsRange(start: start, end: end, calendar: cal)
    let datesAll = rows.map { $0.date }
    let N = targetCount(for: timeframe)
    let idx = evenStrideIndices(total: datesAll.count, targetCount: N)
    let dates = idx.map { datesAll[$0] }

    var state: UInt64 = 0xA11CE6A5
    func rand() -> Double { state = 6364136223846793005 &* state &+ 1; return Double(state & 0xFFFFFFFFFFFF) / Double(0xFFFFFFFFFFFF) }
    let base: (Double, Double)
    switch timeframe {
    case .oneDay: base = (1_000, 3_000)
    case .oneWeek: base = (1_500, 4_000)
    case .oneMonth: base = (2_000, 5_000)
    case .oneYear: base = (2_500, 6_000)
    case .ytd: base = (2_500, 6_000)
    case .all: base = (2_000, 5_500)
    }
    return dates.map { d in
        let v = base.0 + (base.1 - base.0) * (0.6 * rand() + 0.4)
        return GasFeesPoint(date: d, value: v)
    }
}

public func mockViewMonthCategories() -> [ViewMonthCategory] {
    let cal = Calendar.current
    let startMonth = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
    var items: [ViewMonthCategory] = []
    for i in 0..<36 {
        let date = cal.date(byAdding: .month, value: -i, to: startMonth)!
        let monthIndex = i % 12
        let seasonal = 0.8 + 0.4 * sin(Double(monthIndex) / 12.0 * 2.0 * .pi)
        let base = 50_000
        let value = Int(Double(base) * seasonal)
        items.append(ViewMonthCategory(date: date, viewCount: value))
    }
    return items.sorted { $0.date < $1.date }
}


// MARK: - Simple downsampling helpers
private func evenStrideIndices(total: Int, targetCount: Int) -> [Int] {
    guard total > 0, targetCount > 0 else { return [] }
    if targetCount >= total { return Array(0..<total) }
    let step = Double(total - 1) / Double(max(1, targetCount - 1))
    return (0..<targetCount).map { i in Int(round(Double(i) * step)) }
}

private func targetCount(for timeframe: Timeframe) -> Int {
    switch timeframe {
    case .oneDay: return 12
    case .oneWeek: return 14
    case .oneMonth: return 30
    case .oneYear: return 60
    case .ytd: return 60
    case .all: return 120
    }
}

// MARK: - Aggregation helpers for stacked bar (Top 9 + Other over last 2 years)
public func top9PlusOtherFeesLastTwoYears(metrics: [DAppMetric], now: Date = Date(), calendar cal: Calendar = .current) -> [(date: Date, value: Double, project: String)] {
    // Determine 2-year window
    let start = cal.date(byAdding: .year, value: -2, to: now) ?? now
    // Sum fees per dappId inside window
    var sumById: [String: Double] = [:]
    for m in metrics where m.date >= start && m.date <= now {
        let v = m.tradingFees ?? 0
        guard v != 0 else { continue }
        sumById[m.dappId, default: 0] += v
    }
    // Map ids to display names
    let nameMap = nameByDappId()
    // Sort descending and split Top 9 vs Other
    let sorted = sumById.sorted { $0.value > $1.value }
    let top = sorted.prefix(9)
    let otherSum = sorted.dropFirst(9).reduce(0.0) { $0 + $1.value }

    // Use a single bucket date (start of current month) so the chart renders one bar
    let bucketDate = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? cal.startOfDay(for: now)

    var points: [(date: Date, value: Double, project: String)] = []
    points.reserveCapacity(top.count + 1)

    for (id, val) in top {
        let name = nameMap[id] ?? "Project"
        points.append((date: bucketDate, value: val, project: name))
    }
    // Always include an Others bucket; if there is no remainder, synthesize a small visible value
    let topTotal = top.reduce(0.0) { $0 + $1.value }
    let othersValue = (otherSum > 0) ? otherSum : max(1.0, topTotal * 0.06) // ~6% of top total, min 1.0
    points.append((date: bucketDate, value: othersValue, project: "Others"))

    return points
}

// MARK: - Networks model (single source of truth)
public enum Network: String, CaseIterable, Identifiable, Codable, Hashable {
    case moonbeam
    case moonriver
    case mantle
    case eigenlayer
    case zksync

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .moonbeam: return "Moonbeam"
        case .moonriver: return "Moonriver"
        case .mantle: return "Mantle"
        case .eigenlayer: return "EigenLayer"
        case .zksync: return "zkSync"
        }
    }
}

public func mockTopGasFeesByProjectTop10(now: Date = Date(), calendar cal: Calendar = .current) -> [(name: String, gasFees: Double)] {
    // Build a 2-year window of deterministic mock metrics using existing generator
    // We reuse mockDAppMetricsDaily to produce realistic fee values per dapp over time.
    let lastDays = 730 // ~2 years
    let metrics = mockDAppMetricsDaily(lastDays: lastDays)

    // Aggregate to total trading fees per project over the last 2 years
    let points = top9PlusOtherFeesLastTwoYears(metrics: metrics, now: now, calendar: cal)

    // Map to (name, gasFees), including "Others"
    let nameGasPairs = points.map { (name: $0.project, gasFees: $0.value) }

    // Take top 10 by gas fees but keep Others if present by appending it at the end when needed
    var sorted = nameGasPairs.sorted { $0.gasFees > $1.gasFees }
    // Ensure "Others" exists (if not present from points, add a small placeholder so domain knows it)
    if !sorted.contains(where: { $0.name == "Others" }) {
        sorted.append((name: "Others", gasFees: 0))
    }
    let top10 = Array(sorted.prefix(10))
    return top10
}

