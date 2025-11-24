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
    // API-aligned: metrics row linked to a DApp/Project via dappId
    var id = UUID()
    let dappId: String
    let date: Date
    let tvl: Double?
    let tradingVolume: Double?
    let tradingFees: Double?
    let capitalEfficiency: Double?
    let dau: Double? // aka UAW
    let txCount: Double? // number of transactions
    let uniqueTraders: Double? // distinct traders/wallets
}

struct DAppDirectoryItem: Identifiable, Codable, Hashable {
    let id: String   // dappId from directory API
    let name: String
    var colorHex: String? = nil // optional placeholder; real API may provide branding
}

func mockDirectoryItems() -> [DAppDirectoryItem] {
    // Ten deterministic directory entries for joining with metrics
    return [
        DAppDirectoryItem(id: "dapp-1", name: "Project Alpha"),
        DAppDirectoryItem(id: "dapp-2", name: "Project Beta"),
        DAppDirectoryItem(id: "dapp-3", name: "Project Gamma"),
        DAppDirectoryItem(id: "dapp-4", name: "Project Delta"),
        DAppDirectoryItem(id: "dapp-5", name: "Project Epsilon"),
        DAppDirectoryItem(id: "dapp-6", name: "Project Zeta"),
        DAppDirectoryItem(id: "dapp-7", name: "Project Eta"),
        DAppDirectoryItem(id: "dapp-8", name: "Project Theta"),
        DAppDirectoryItem(id: "dapp-9", name: "Project Iota"),
        DAppDirectoryItem(id: "dapp-10", name: "Project Kappa")
    ]
}

func mockDAppMetrics(lastMonths: Int = 12, calendar cal: Calendar = .current) -> [DAppMetric] {
    let start = startOfCurrentMonth(cal)
    let directory = mockDirectoryItems()
    var all: [DAppMetric] = []
    for (idx, dapp) in directory.enumerated() {
        for offset in (0..<lastMonths).reversed() {
            guard let date = cal.date(byAdding: .month, value: -offset, to: start) else { continue }
            let m = cal.component(.month, from: date)
            // Deterministic scaling per dapp to create ranking variance
            let baseScale = 1.0 + Double(idx) * 0.12
            let seasonal = seasonality(month: m, amplitude: 0.12)
            let tvl = (18_000_000.0 + Double(m) * 600_000.0) * seasonal * baseScale
            let volume = (4_000_000.0 + Double(m) * 300_000.0) * seasonal * baseScale
            let fees = volume * (0.0018 + 0.0002 * Double((idx % 3)))
            let capEff = volume / max(tvl, 1)
            let uaw = (40_000.0 + Double(m) * 2_200.0) * seasonal * baseScale
            let tx = volume / 230.0
            let traders = uaw * (0.52 + 0.02 * Double(idx % 4))
            all.append(DAppMetric(dappId: dapp.id, date: date, tvl: tvl, tradingVolume: volume, tradingFees: fees, capitalEfficiency: capEff, dau: uaw, txCount: tx, uniqueTraders: traders))
        }
    }
    return all.sorted { $0.date < $1.date }
}

func mockLatestMetricsPerDapp(calendar cal: Calendar = .current) -> [DAppMetric] {
    let metrics = mockDAppMetrics(lastMonths: 12, calendar: cal)
    // Group by dappId and pick the newest date per group
    let grouped = Dictionary(grouping: metrics, by: { $0.dappId })
    return grouped.values.compactMap { rows in
        rows.max(by: { $0.date < $1.date })
    }
}

struct DAppDisplayRow: Identifiable {
    let id: String      // dappId
    let name: String
    let tradingFees: Double
}

func mockTop10FeesWithNames(calendar cal: Calendar = .current) -> [DAppDisplayRow] {
    let latest = mockLatestMetricsPerDapp(calendar: cal)
    let directory = mockDirectoryItems()
    let nameById = Dictionary(uniqueKeysWithValues: directory.map { ($0.id, $0.name) })
    let rows: [DAppDisplayRow] = latest.map { metric in
        DAppDisplayRow(id: metric.dappId, name: nameById[metric.dappId] ?? "Project", tradingFees: metric.tradingFees ?? 0)
    }
    return rows.sorted { $0.tradingFees > $1.tradingFees }.prefix(10).map { $0 }
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

//Asset-level metric rows matching AssetsMetricsDto.Metric
struct AssetMetric: Identifiable, Codable {
    var id = UUID()
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
        return DAppMetric(dappId: "dapp-1", date: date, tvl: tvl, tradingVolume: volume, tradingFees: fees, capitalEfficiency: capEff, dau: uaw, txCount: tx, uniqueTraders: traders)
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

// Lookup helper matching directory API to metrics by dappId
func nameByDappId() -> [String: String] {
    let directory = mockDirectoryItems()
    return Dictionary(uniqueKeysWithValues: directory.map { ($0.id, $0.name) })
}

// If you need additional mock data sets, add similar helpers here.

// MARK: - Top Projects Displays for mock cards
struct TopProjectDisplay: Identifiable {
    let id: String      // dappId
    let name: String
    let uaw: Double     // dau in metrics
    let transactions: Double // txCount in metrics
}

/// Top projects by latest UAW (DAU)
func mockTopProjectsByUAW(limit: Int = 4, calendar cal: Calendar = .current) -> [TopProjectDisplay] {
    let latest = mockLatestMetricsPerDapp(calendar: cal)
    let nameMap = nameByDappId()
    let rows: [TopProjectDisplay] = latest.map { m in
        TopProjectDisplay(id: m.dappId, name: nameMap[m.dappId] ?? "Project", uaw: m.dau ?? 0, transactions: m.txCount ?? 0)
    }
    return rows.sorted { $0.uaw > $1.uaw }.prefix(limit).map { $0 }
}

/// Top projects by latest Transactions (txCount)
func mockTopProjectsByTransactions(limit: Int = 4, calendar cal: Calendar = .current) -> [TopProjectDisplay] {
    let latest = mockLatestMetricsPerDapp(calendar: cal)
    let nameMap = nameByDappId()
    let rows: [TopProjectDisplay] = latest.map { m in
        TopProjectDisplay(id: m.dappId, name: nameMap[m.dappId] ?? "Project", uaw: m.dau ?? 0, transactions: m.txCount ?? 0)
    }
    return rows.sorted { $0.transactions > $1.transactions }.prefix(limit).map { $0 }
}

/// Top projects by a combined score of normalized UAW and Transactions
func mockTopProjectsCombined(limit: Int = 4, calendar cal: Calendar = .current) -> [TopProjectDisplay] {
    let latest = mockLatestMetricsPerDapp(calendar: cal)
    let nameMap = nameByDappId()
    let rows: [TopProjectDisplay] = latest.map { m in
        TopProjectDisplay(id: m.dappId, name: nameMap[m.dappId] ?? "Project", uaw: m.dau ?? 0, transactions: m.txCount ?? 0)
    }
    guard !rows.isEmpty else { return [] }
    let maxUAW = rows.map { $0.uaw }.max() ?? 1
    let maxTX = rows.map { $0.transactions }.max() ?? 1
    let scored = rows.map { r -> (TopProjectDisplay, Double) in
        let u = maxUAW > 0 ? r.uaw / maxUAW : 0
        let t = maxTX > 0 ? r.transactions / maxTX : 0
        return (r, u + t)
    }
    return scored.sorted { $0.1 > $1.1 }.prefix(limit).map { $0.0 }
}

// MARK: - Category + Network hierarchy for Explore
// Removed duplicate Network enum as requested

enum CategoryKind: String, CaseIterable, Codable {
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
}

struct ProjectCatalog: Identifiable, Codable, Hashable {
    let id: String       // dappId compatible
    let name: String
    let category: CategoryKind
}

/// Returns a deterministic list of projects for a given network. ~20+ per category.
func mockProjectsForNetwork(_ network: Network) -> [ProjectCatalog] {
    let categories: [CategoryKind] = [.defi, .gaming, .nfts, .wallets, .bridges, .lending, .social, .dex, .dao, .depin, .infrastructure, .overview]
    var items: [ProjectCatalog] = []
    var counter = 1
    for cat in categories {
        for idx in 1...22 {
            let id = "\(network.rawValue)-dapp-\(counter)"
            let name = "\(cat.rawValue) Project \(String(format: "%02d", idx))"
            items.append(ProjectCatalog(id: id, name: name, category: cat))
            counter += 1
        }
    }
    for idx in 1...22 {
        let id = "\(network.rawValue)-dapp-\(counter)"
        let name = "Other Project \(String(format: "%02d", idx))"
        items.append(ProjectCatalog(id: id, name: name, category: .other))
        counter += 1
    }
    return items
}

/// Deterministic per-project monthly metrics (12 months) leveraging the same seasonality.
func mockProjectMetrics(lastMonths: Int = 12, network: Network, calendar cal: Calendar = .current) -> [DAppMetric] {
    let start = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
    let catalog = mockProjectsForNetwork(network)
    var all: [DAppMetric] = []
    for (idx, p) in catalog.enumerated() {
        for offset in (0..<lastMonths).reversed() {
            guard let date = cal.date(byAdding: .month, value: -offset, to: start) else { continue }
            let m = cal.component(.month, from: date)
            // Category-based base levels to create realistic spread
            let baseUAW: Double
            let baseVol: Double
            switch p.category {
            case .defi, .dex: baseUAW = 60_000; baseVol = 1_800_000
            case .gaming: baseUAW = 55_000; baseVol = 900_000
            case .nfts: baseUAW = 35_000; baseVol = 600_000
            case .wallets: baseUAW = 28_000; baseVol = 300_000
            case .bridges: baseUAW = 22_000; baseVol = 1_200_000
            case .lending: baseUAW = 26_000; baseVol = 1_000_000
            case .social: baseUAW = 24_000; baseVol = 400_000
            case .dao: baseUAW = 18_000; baseVol = 200_000
            case .depin: baseUAW = 16_000; baseVol = 150_000
            case .infrastructure: baseUAW = 14_000; baseVol = 120_000
            case .overview: baseUAW = 10_000; baseVol = 100_000
            case .other: baseUAW = 12_000; baseVol = 110_000
            }
            // Deterministic scaling per project to create ranking variance
            let baseScale = 1.0 + Double((idx + network.rawValue.hashValue & 0xFF) % 25) * 0.06
            let seasonal = seasonality(month: m, amplitude: 0.12)
            let uaw = max(1, baseUAW * baseScale * seasonal)
            let volume = max(1, baseVol * baseScale * seasonal)
            let tx = volume / 220.0
            let fees = volume * 0.0018
            let tvl = volume * 8.0
            let capEff = volume / max(tvl, 1)
            let traders = uaw * 0.55
            all.append(DAppMetric(dappId: p.id, date: date, tvl: tvl, tradingVolume: volume, tradingFees: fees, capitalEfficiency: capEff, dau: uaw, txCount: tx, uniqueTraders: traders))
        }
    }
    return all.sorted { $0.date < $1.date }
}

/// Latest metrics per project for a network
func mockLatestProjectMetrics(network: Network, calendar cal: Calendar = .current) -> [DAppMetric] {
    let metrics = mockProjectMetrics(lastMonths: 12, network: network, calendar: cal)
    let grouped = Dictionary(grouping: metrics, by: { $0.dappId })
    return grouped.values.compactMap { rows in rows.max(by: { $0.date < $1.date }) }
}

struct CategoryRollup: Identifiable {
    let id: CategoryKind
    let name: String
    let totalUAW: Double
    let totalTransactions: Double
    let projectCount: Int
}

/// Aggregate latest metrics per category for a network
func mockCategoryRollups(for network: Network, calendar cal: Calendar = .current) -> [CategoryRollup] {
    let latest = mockLatestProjectMetrics(network: network, calendar: cal)
    let catalogById = Dictionary(uniqueKeysWithValues: mockProjectsForNetwork(network).map { ($0.id, $0) })
    var sums: [CategoryKind: (uaw: Double, tx: Double, count: Int)] = [:]
    for m in latest {
        guard let p = catalogById[m.dappId] else { continue }
        let u = m.dau ?? 0
        let t = m.txCount ?? 0
        let prev = sums[p.category] ?? (0, 0, 0)
        sums[p.category] = (prev.uaw + u, prev.tx + t, prev.count + 1)
    }
    return sums.map { (kind, agg) in
        CategoryRollup(id: kind, name: kind.rawValue, totalUAW: agg.uaw, totalTransactions: agg.tx, projectCount: agg.count)
    }
}

/// Top 3 categories by combined normalized score + synthesized Other bucket as 4th card
func mockTopCategories(for network: Network, calendar cal: Calendar = .current) -> [CategoryRollup] {
    let rollups = mockCategoryRollups(for: network, calendar: cal)
    guard !rollups.isEmpty else { return [] }
    let maxU = rollups.map { $0.totalUAW }.max() ?? 1
    let maxT = rollups.map { $0.totalTransactions }.max() ?? 1
    let scored = rollups.map { r -> (CategoryRollup, Double) in
        let u = maxU > 0 ? r.totalUAW / maxU : 0
        let t = maxT > 0 ? r.totalTransactions / maxT : 0
        return (r, u + t)
    }.sorted { $0.1 > $1.1 }

    let top3 = scored.prefix(3).map { $0.0 }
    let remainingKinds = Set(rollups.map { $0.id }).subtracting(top3.map { $0.id })
    let others = rollups.filter { remainingKinds.contains($0.id) }
    let otherRollup = CategoryRollup(id: .other, name: CategoryKind.other.rawValue, totalUAW: others.reduce(0) { $0 + $1.totalUAW }, totalTransactions: others.reduce(0) { $0 + $1.totalTransactions }, projectCount: others.reduce(0) { $0 + $1.projectCount })
    return top3 + [otherRollup]
}

/// Top projects within a category by combined normalized score
func mockTopProjects(in category: CategoryKind, for network: Network, limit: Int = 10, calendar cal: Calendar = .current) -> [TopProjectDisplay] {
    let latest = mockLatestProjectMetrics(network: network, calendar: cal)
    let catalogById = Dictionary(uniqueKeysWithValues: mockProjectsForNetwork(network).filter { $0.category == category }.map { ($0.id, $0) })
    let rows: [TopProjectDisplay] = latest.compactMap { m in
        guard catalogById[m.dappId] != nil else { return nil }
        return TopProjectDisplay(id: m.dappId, name: catalogById[m.dappId]!.name, uaw: m.dau ?? 0, transactions: m.txCount ?? 0)
    }
    guard !rows.isEmpty else { return [] }
    let maxU = rows.map { $0.uaw }.max() ?? 1
    let maxT = rows.map { $0.transactions }.max() ?? 1
    let scored = rows.map { r -> (TopProjectDisplay, Double) in
        let u = maxU > 0 ? r.uaw / maxU : 0
        let t = maxT > 0 ? r.transactions / maxT : 0
        return (r, u + t)
    }
    return scored.sorted { $0.1 > $1.1 }.prefix(limit).map { $0.0 }
}

// MARK: - Example Category Mock Data (fixed, preview-friendly)

/// Returns a fixed, preview-friendly set of top categories (Top 3 + Other) for a network.
/// Values are deterministic and chosen to look realistic without depending on other generators.
func mockExampleTopCategories(for network: Network) -> [CategoryRollup] {
    // Deterministic scaling per network to vary values slightly across networks
    let base: Double
    switch network {
    case .moonbeam: base = 1.00
    case .mantle: base = 1.08
    case .eigenlayer: base = 0.95
    case .zksync: base = 1.12
    case .moonriver: base = 0.9
    }
    let defi = CategoryRollup(id: .defi, name: CategoryKind.defi.rawValue,
                              totalUAW: 320_000 * base, totalTransactions: 5_800_000 * base, projectCount: 120)
    let gaming = CategoryRollup(id: .gaming, name: CategoryKind.gaming.rawValue,
                                totalUAW: 270_000 * base, totalTransactions: 3_100_000 * base, projectCount: 95)
    let nfts = CategoryRollup(id: .nfts, name: CategoryKind.nfts.rawValue,
                              totalUAW: 180_000 * base, totalTransactions: 2_400_000 * base, projectCount: 80)
    let other = CategoryRollup(id: .other, name: CategoryKind.other.rawValue,
                               totalUAW: 210_000 * base, totalTransactions: 2_900_000 * base, projectCount: 140)
    return [defi, gaming, nfts, other]
}

/// Returns a full set of category rollups for display/testing without backend.
/// Includes all primary categories with deterministic values.
func mockExampleCategoryRollups(for network: Network) -> [CategoryRollup] {
    let scale: Double
    switch network {
    case .moonbeam: scale = 1.0
    case .mantle: scale = 1.05
    case .eigenlayer: scale = 0.92
    case .zksync: scale = 1.15
    case .moonriver: scale = 0.88
    }
    func roll(_ kind: CategoryKind, uaw: Double, tx: Double, count: Int) -> CategoryRollup {
        CategoryRollup(id: kind, name: kind.rawValue, totalUAW: uaw * scale, totalTransactions: tx * scale, projectCount: count)
    }
    let rows: [CategoryRollup] = [
        roll(.defi, uaw: 320_000, tx: 5_800_000, count: 120),
        roll(.gaming, uaw: 270_000, tx: 3_100_000, count: 95),
        roll(.nfts, uaw: 180_000, tx: 2_400_000, count: 80),
        roll(.wallets, uaw: 95_000, tx: 1_100_000, count: 60),
        roll(.bridges, uaw: 85_000, tx: 1_300_000, count: 40),
        roll(.lending, uaw: 120_000, tx: 2_000_000, count: 55),
        roll(.social, uaw: 70_000, tx: 650_000, count: 35),
        roll(.dex, uaw: 210_000, tx: 3_800_000, count: 75),
        roll(.dao, uaw: 45_000, tx: 280_000, count: 22),
        roll(.depin, uaw: 38_000, tx: 190_000, count: 18),
        roll(.infrastructure, uaw: 28_000, tx: 120_000, count: 15),
        roll(.overview, uaw: 10_000, tx: 100_000, count: 10),
        roll(.other, uaw: 210_000, tx: 2_900_000, count: 140)
    ]
    return rows
}

/// Deterministic top projects for a category using the example rollups, for simple cards/lists.
func mockExampleTopProjects(in category: CategoryKind, for network: Network, limit: Int = 10) -> [TopProjectDisplay] {
    // Build deterministic project names per category
    let baseNames = (1...max(limit, 10)).map { idx in
        "\(category.rawValue) Project \(String(format: "%02d", idx))"
    }
    // Derive base levels from the example rollups for rough consistency
    let rollups = mockExampleCategoryRollups(for: network)
    let map = Dictionary(uniqueKeysWithValues: rollups.map { ($0.id, $0) })
    let baseU = (map[category]?.totalUAW ?? 100_000) / Double(max(limit, 10))
    let baseT = (map[category]?.totalTransactions ?? 1_000_000) / Double(max(limit, 10))
    return baseNames.prefix(limit).enumerated().map { (i, name) in
        let factor = 1.0 + 0.05 * Double((i % 5)) // small spread
        return TopProjectDisplay(id: "example-\(category.rawValue.lowercased())-\(i+1)",
                                 name: name,
                                 uaw: max(1, baseU * factor),
                                 transactions: max(1, baseT * factor))
    }
}

extension Network {
    var displayName: String {
        switch self {
        case .moonbeam: return "Moonbeam"
        case .mantle: return "Mantle"
        case .eigenlayer: return "Eigenlayer"
        case .zksync: return "zkSync"
        case .moonriver: return "Moonriver"
        }
    }

    var iconName: String {
        switch self {
        case .moonbeam: return "moonbeam"
        case .mantle: return "mantle"
        case .eigenlayer: return "eigenlayer"
        case .zksync: return "zksync"
        case .moonriver: return "moonriver"
        }
    }
}
