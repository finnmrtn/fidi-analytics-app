import Foundation

/// Represents an aggregated rollup of analytics for a given category.
/// This is a minimal model to satisfy repository and mock usages.
public struct CategoryRollup: Hashable, Codable, Sendable {
    /// The category identifier.
    public let category: CategoryKind
    /// Total value for the selected window (e.g., UAW, transactions, etc.).
    public let total: Double
    /// Optional per-network breakdown for the category.
    public let perNetwork: [NetworkBreakdown]

    public init(category: CategoryKind, total: Double, perNetwork: [NetworkBreakdown] = []) {
        self.category = category
        self.total = total
        self.perNetwork = perNetwork
    }
}

/// A lightweight representation of a network-specific value for a category.
public struct NetworkBreakdown: Hashable, Codable, Sendable {
    public let network: Network
    public let value: Double

    public init(network: Network, value: Double) {
        self.network = network
        self.value = value
    }
}

/// A minimal enum describing high-level DApp categories.
/// If your project already defines `CategoryKind` elsewhere, remove this and use that definition instead.
public enum CategoryKind: String, CaseIterable, Codable, Sendable {
    case defi
    case nft
    case gaming
    case dax
    case social
    case other
}

/// A minimal network enum placeholder.
/// If your project already defines `Network` elsewhere, remove this and use that definition instead.
public enum Network: String, CaseIterable, Codable, Sendable {
    case ethereum
    case polygon
    case solana
    case arbitrum
    case optimism
    case base
}
