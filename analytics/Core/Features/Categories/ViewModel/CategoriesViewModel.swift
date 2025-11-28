//
//  CategoriesViewModel.swift
//  analytics
//
//  Created by Assistant
//

import SwiftUI
import Observation
import Foundation

// Local shims are given distinct names to avoid conflicts with shared models
enum LocalNetworkShim: String, CaseIterable, Codable {
    case moonbeam
    case moonriver
    case mantle
    case eigenlayer
    case zksync
}

enum LocalCategoryKindShim: String, CaseIterable, Codable, Hashable, Identifiable {
    case dex
    case nft
    case gaming
    case lending
    case bridge
    case infrastructure
    case other

    var id: String { rawValue }
}

struct TopProjectDisplay: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let category: LocalCategoryKindShim
    let network: LocalNetworkShim
    let transactions: Double
    let uaw: Double
}

struct LocalCategoryRollup: Identifiable, Codable, Hashable {
    let kind: LocalCategoryKindShim
    let id: String
    let name: String
    let totalUAW: Double
    let totalTransactions: Double
    let projectCount: Int
}

@Observable
class CategoriesViewModel {
    private let repo: AnalyticsRepository

    struct RankingWeights {
        let tx: Double
        let uaw: Double
        static let `default` = RankingWeights(tx: 0.5, uaw: 0.5)
    }
    
    var selectedNetwork: LocalNetworkShim = .moonbeam
    var selectedAggregation: Aggregation = .sum
    var filterStartDate: Date?
    var filterEndDate: Date?
    
    // Top categories for the selected network
    var topCategories: [LocalCategoryRollup] = []
    
    // Pie chart data
    var pieChartData: [(name: String, value: Double, color: Color)] = []
    
    struct SeriesPoint: Hashable, Codable {
        let date: Date
        let value: Double
    }

    // Prepared chart data
    // Transactions: area chart with broader coverage
    private(set) var transactionsSeries: [String: [SeriesPoint]] = [:] // key: project id or "Other"
    // UAW and Fees: daily bars (one sample per day)
    private(set) var uawDailyBars: [String: [SeriesPoint]] = [:]
    private(set) var feesDailyBars: [String: [SeriesPoint]] = [:]

    init(repo: AnalyticsRepository = MockAnalyticsRepository()) {
        self.repo = repo
        loadData()
    }
    
    func loadData() {
        // Map LocalNetworkShim to shared Network
        let sharedNetwork: Network
        switch selectedNetwork {
        case .moonbeam: sharedNetwork = .moonbeam
        case .moonriver: sharedNetwork = .moonriver
        case .mantle: sharedNetwork = .mantle
        case .eigenlayer: sharedNetwork = .eigenlayer
        case .zksync: sharedNetwork = .zksync
        }

        // Build deterministic example rollups locally (no dependency on MockData helpers)
        let baseKinds: [LocalCategoryKindShim] = [.dex, .nft, .gaming, .lending]
        self.topCategories = baseKinds.enumerated().map { (idx, kind) in
            let name: String = {
                switch kind {
                case .dex: return "DEX"
                case .nft: return "NFTs"
                case .gaming: return "Gaming"
                case .lending: return "Lending"
                case .bridge: return "Bridges"
                case .infrastructure: return "Infrastructure"
                case .other: return "Other"
                }
            }()
            let totalUAW = Double(10_000 + idx * 1_000)
            let totalTransactions = Double(50_000 + idx * 5_000)
            let projectCount = 5 + idx
            return LocalCategoryRollup(
                kind: kind,
                id: UUID().uuidString,
                name: name,
                totalUAW: totalUAW,
                totalTransactions: totalTransactions,
                projectCount: projectCount
            )
        }

        // Enforce Top 3 + Other
        if topCategories.count > 3 {
            let top3 = Array(topCategories.prefix(3))
            let rest = topCategories.dropFirst(3)
            let otherU = rest.reduce(0) { $0 + $1.totalUAW }
            let otherT = rest.reduce(0) { $0 + $1.totalTransactions }
            let otherCount = rest.reduce(0) { $0 + $1.projectCount }
            let other = LocalCategoryRollup(kind: .other, id: LocalCategoryKindShim.other.rawValue, name: "Other", totalUAW: otherU, totalTransactions: otherT, projectCount: otherCount)
            self.topCategories = top3 + [other]
        }

        // Pie data
        let colors: [Color] = [Color(hex: "#FDD835"), Color(hex: "#7E88FF"), Color(hex: "#73BAFF"), Color(hex: "#F4F5F8")]
        self.pieChartData = self.topCategories.enumerated().map { (idx, cat) in
            let value = cat.totalUAW + cat.totalTransactions
            let color = idx < colors.count ? colors[idx] : .gray
            return (name: cat.name, value: value, color: color)
        }

        // Prepare project series using shared mockProjectMetrics
        self.prepareProjectSeries(for: sharedNetwork)
    }
    
    private func mapSharedKindToLocal(_ kind: CategoryKind) -> LocalCategoryKindShim {
        switch kind {
        case .dex: return .dex
        case .nfts: return .nft
        case .gaming: return .gaming
        case .lending: return .lending
        case .bridges: return .bridge
        case .infrastructure: return .infrastructure
        default: return .other
        }
    }
    
    func updateNetwork(_ network: LocalNetworkShim) {
        selectedNetwork = network
        loadData()
    }
    
    // Get formatted total for display
    var totalUAW: String {
        let total = topCategories.reduce(0) { $0 + $1.totalUAW }
        return formatNumber(total)
    }
    
    var totalTransactions: String {
        let total = topCategories.reduce(0) { $0 + $1.totalTransactions }
        return formatNumber(total)
    }
    
    var selectionLabel: String {
        if let start = filterStartDate, let end = filterEndDate {
            let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
            if days <= 8 { return "1W" }
            if days <= 35 { return "1M" }
            if days <= 100 { return "3M" }
            if days <= 400 { return "1Y" }
            return "Custom"
        } else {
            return "ALL"
        }
    }
    
    private func formatNumber(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fk", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    /// Returns the top N projects for a given category and network, ranked by a weighted combination of
    /// transactions and unique active wallets (UAW). Uses example API-backed data via repository.
    /// - Parameters:
    ///   - category: The category to query.
    ///   - network: The network to filter on.
    ///   - limit: Maximum number of rows to return. Default 10.
    ///   - weights: Weights applied to normalized transactions and UAW. Default 0.5/0.5.
    /// - Returns: An array of TopProjectDisplay sorted by descending score.
    func rankedTopProjects(
        for category: LocalCategoryKindShim,
        on network: LocalNetworkShim,
        limit: Int = 10,
        weights: RankingWeights = .default
    ) -> [TopProjectDisplay] {
        let sharedCategory: CategoryKind
        switch category {
        case .dex: sharedCategory = .dex
        case .nft: sharedCategory = .nfts
        case .gaming: sharedCategory = .gaming
        case .lending: sharedCategory = .lending
        case .bridge: sharedCategory = .bridges
        case .infrastructure: sharedCategory = .infrastructure
        case .other: sharedCategory = .other
        }
        let sharedNetwork: Network
        switch network {
        case .moonbeam: sharedNetwork = .moonbeam
        case .moonriver: sharedNetwork = .moonriver
        case .mantle: sharedNetwork = .mantle
        case .eigenlayer: sharedNetwork = .eigenlayer
        case .zksync: sharedNetwork = .zksync
        }
        return mockTopProjects(in: category, for: network, limit: limit)
    }
    
    /// Returns four slices for display: top 3 categories and an aggregated "Other" slice.
    /// Colors are assigned to match the UI design.
    func topThreePlusOtherSlices() -> [(name: String, id: LocalCategoryKindShim, totalTransactions: Double, totalUAW: Double, color: Color)] {
        let colors: [Color] = [
            Color(hex: "#FDD835"),
            Color(hex: "#7E88FF"),
            Color(hex: "#73BAFF")
        ]
        let otherColor = Color(hex: "#DBDEE0")

        var slices: [(name: String, id: LocalCategoryKindShim, totalTransactions: Double, totalUAW: Double, color: Color)] = []
        let categories = topCategories

        // Add up to first 3 categories with corresponding colors if available
        for index in 0..<3 {
            if index < categories.count {
                let cat = categories[index]
                slices.append((name: cat.name, id: cat.kind, totalTransactions: cat.totalTransactions, totalUAW: cat.totalUAW, color: colors[index]))
            }
        }

        // Sum the rest as Other
        let rest = categories.dropFirst(3)
        let otherTransactions = rest.reduce(0) { $0 + $1.totalTransactions }
        let otherUAW = rest.reduce(0) { $0 + $1.totalUAW }
        // Always include an Other slice to keep 4 slices in UI
        slices.append((name: "Other", id: LocalCategoryKindShim.other, totalTransactions: otherTransactions, totalUAW: otherUAW, color: otherColor))

        return slices
    }

    /// Public pretty number formatter for view consumption
    func prettyNumber(_ value: Double) -> String {
        if !value.isFinite { return "—" }
        let absValue = Swift.abs(value)
        if absValue >= 1_000_000 {
            let scaled = value / 1_000_000
            return scaled.formatted(.number.precision(.fractionLength(0...1))) + "M"
        } else if absValue >= 1_000 {
            let scaled = value / 1_000
            return scaled.formatted(.number.precision(.fractionLength(0...1))) + "k"
        } else {
            return value.formatted(.number.precision(.fractionLength(0)))
        }
    }
    
    private func prepareProjectSeries(for network: Network) {
        let cal = Calendar.current
        let start = filterStartDate ?? cal.date(byAdding: .month, value: -6, to: Date())!
        let end = filterEndDate ?? Date()

        // Map shared Network to local shim for mock
        let localNet: LocalNetworkShim
        switch network {
        case .moonbeam: localNet = .moonbeam
        case .moonriver: localNet = .moonriver
        case .mantle: localNet = .mantle
        case .eigenlayer: localNet = .eigenlayer
        case .zksync: localNet = .zksync
        }
        let metrics = mockProjectMetrics(lastMonths: 12, network: localNet)

        let filtered = metrics.filter { $0.date >= start && $0.date <= end }

        // Aggregate totals per project to rank by Transactions
        let totalsByProject: [String: (tx: Double, uaw: Double)] = filtered.reduce(into: [:]) { dict, m in
            var entry = dict[m.dappId] ?? (tx: 0, uaw: 0)
            entry.tx += (m.txCount ?? 0)
            entry.uaw += (m.dau ?? 0)
            dict[m.dappId] = entry
        }
        let sortedProjects = totalsByProject.sorted { $0.value.tx > $1.value.tx }.map { $0.key }
        let top9 = Array(sortedProjects.prefix(9))
        let top9Set = Set(top9)

        // Group by day per project
        let byProjectDay: [String: [Date: (tx: Double, uaw: Double, fees: Double)]] = filtered.reduce(into: [:]) { dict, m in
            let day = cal.startOfDay(for: m.date)
            var dayMap = dict[m.dappId] ?? [:]
            var agg = dayMap[day] ?? (tx: 0, uaw: 0, fees: 0)
            agg.tx += (m.txCount ?? 0)
            agg.uaw += (m.dau ?? 0)
            // fees derived from volume if available; keep 0 in mocks
            dayMap[day] = agg
            dict[m.dappId] = dayMap
        }

        // Build continuous daily timeline
        var timeline: [Date] = []
        var d = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)
        while d <= endDay { timeline.append(d); d = cal.date(byAdding: .day, value: 1, to: d)! }

        var txSeries: [String: [SeriesPoint]] = [:]
        var uawSeries: [String: [SeriesPoint]] = [:]
        var feesSeries: [String: [SeriesPoint]] = [:]

        // Total per day across all projects
        var totalPerDay: [Date: (tx: Double, uaw: Double, fees: Double)] = [:]
        for (_, dayMap) in byProjectDay {
            for (day, agg) in dayMap {
                var t = totalPerDay[day] ?? (tx: 0, uaw: 0, fees: 0)
                t.tx += agg.tx; t.uaw += agg.uaw; t.fees += agg.fees
                totalPerDay[day] = t
            }
        }

        // Per-project series for top9
        for pid in byProjectDay.keys where top9Set.contains(pid) {
            let dayMap = byProjectDay[pid] ?? [:]
            let txPoints = timeline.map { SeriesPoint(date: $0, value: dayMap[$0]?.tx ?? 0) }
            let uawPoints = timeline.map { SeriesPoint(date: $0, value: dayMap[$0]?.uaw ?? 0) }
            let feePoints = timeline.map { SeriesPoint(date: $0, value: dayMap[$0]?.fees ?? 0) }
            txSeries[pid] = txPoints
            uawSeries[pid] = uawPoints
            feesSeries[pid] = feePoints
        }

        // Compute Other as total - sum(top9)
        var otherTX: [SeriesPoint] = []
        var otherUAW: [SeriesPoint] = []
        var otherFees: [SeriesPoint] = []
        for (idx, day) in timeline.enumerated() {
            let total = totalPerDay[day] ?? (tx: 0, uaw: 0, fees: 0)
            var topTx = 0.0, topU = 0.0, topF = 0.0
            for pid in top9 {
                topTx += txSeries[pid]?[idx].value ?? 0
                topU += uawSeries[pid]?[idx].value ?? 0
                topF += feesSeries[pid]?[idx].value ?? 0
            }
            otherTX.append(SeriesPoint(date: day, value: max(0, total.tx - topTx)))
            otherUAW.append(SeriesPoint(date: day, value: max(0, total.uaw - topU)))
            otherFees.append(SeriesPoint(date: day, value: max(0, total.fees - topF)))
        }

        txSeries["Other"] = otherTX
        uawSeries["Other"] = otherUAW
        feesSeries["Other"] = otherFees
        self.transactionsSeries = txSeries
        self.uawDailyBars = uawSeries
        self.feesDailyBars = feesSeries
    }
}

extension CategoriesViewModel {
    private func fetchTopProjectsSync(category: LocalCategoryKindShim, network: LocalNetworkShim, limit: Int, weights: RankingWeights) -> [TopProjectDisplay] {
        let sharedCategory: CategoryKind
        switch category {
        case .dex: sharedCategory = .dex
        case .nft: sharedCategory = .nfts
        case .gaming: sharedCategory = .gaming
        case .lending: sharedCategory = .lending
        case .bridge: sharedCategory = .bridges
        case .infrastructure: sharedCategory = .infrastructure
        case .other: sharedCategory = .other
        }
        let sharedNetwork: Network
        switch network {
        case .moonbeam: sharedNetwork = .moonbeam
        case .moonriver: sharedNetwork = .moonriver
        case .mantle: sharedNetwork = .mantle
        case .eigenlayer: sharedNetwork = .eigenlayer
        case .zksync: sharedNetwork = .zksync
        }
        return mockTopProjects(in: category, for: network, limit: limit)
    }
}

extension Color {
    init(hex hexString: String) {
        var hex = hexString
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


// MARK: - Local shims to satisfy build (replace with shared models when available)

fileprivate struct ProjectMetric: Identifiable, Codable, Hashable {
    var id: String { dappId + "-" + ISO8601DateFormatter().string(from: date) }
    let dappId: String
    let date: Date
    let dau: Double?
    let txCount: Double?
}

fileprivate struct ProjectCatalogEntry: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: LocalCategoryKindShim
    let network: LocalNetworkShim
}

@discardableResult
fileprivate func mockProjectMetrics(lastMonths: Int, network: LocalNetworkShim) -> [ProjectMetric] {
    let catalog = mockProjectsForNetwork(network)
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let start = calendar.date(byAdding: .month, value: -max(0, lastMonths), to: today) ?? today

    var rows: [ProjectMetric] = []
    for project in catalog {
        // generate roughly one metric per week within the range
        var date = start
        while date <= today {
            let base = Double(abs(project.id.hashValue % 100) + 50)
            let tx = base * (1 + Double(Int.random(in: -20...20)) / 100.0)
            let uaw = (base / 2) * (1 + Double(Int.random(in: -20...20)) / 100.0)
            rows.append(ProjectMetric(dappId: project.id, date: date, dau: max(0, uaw), txCount: max(0, tx)))
            date = calendar.date(byAdding: .day, value: 7, to: date) ?? today
        }
    }
    return rows
}

fileprivate func mockProjectsForNetwork(_ network: LocalNetworkShim) -> [ProjectCatalogEntry] {
    // Use stable sample IDs to keep joins consistent.
    let base: [ProjectCatalogEntry] = [
        ProjectCatalogEntry(id: "dex.alpha", name: "AlphaSwap", category: .dex, network: network),
        ProjectCatalogEntry(id: "nft.gallery", name: "Gallery", category: .nft, network: network),
        ProjectCatalogEntry(id: "game.blaster", name: "Blaster", category: .gaming, network: network),
        ProjectCatalogEntry(id: "lend.hub", name: "LendHub", category: .lending, network: network),
        ProjectCatalogEntry(id: "bridge.port", name: "PortBridge", category: .bridge, network: network),
        ProjectCatalogEntry(id: "infra.index", name: "IndexNode", category: .infrastructure, network: network)
    ]
    return base
}

fileprivate func mockTopProjects(in category: LocalCategoryKindShim, for network: LocalNetworkShim, limit: Int) -> [TopProjectDisplay] {
    let catalog = mockProjectsForNetwork(network).filter { $0.category == category }
    // If none in the catalog for this category, synthesize a few entries.
    let items: [ProjectCatalogEntry]
    if catalog.isEmpty {
        items = (1...max(1, limit)).map { i in
            ProjectCatalogEntry(id: "synthetic.\(category.rawValue).\(i)", name: "\(category.rawValue.capitalized) #\(i)", category: category, network: network)
        }
    } else {
        items = Array(catalog.prefix(max(1, limit)))
    }
    return items.map { entry in
        let seed = Double(abs(entry.id.hashValue % 100) + 50)
        return TopProjectDisplay(
            id: entry.id,
            name: entry.name,
            category: entry.category,
            network: entry.network,
            transactions: seed * 10,
            uaw: seed * 5
        )
    }
}

