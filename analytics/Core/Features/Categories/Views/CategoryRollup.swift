import Foundation

/// Aggregated rollup of analytics for a given category.
/// Uses shared `CategoryKind` and `Network` types defined elsewhere in the project.
public struct CategoryRollup: Codable, Hashable, Sendable {
    public let kind: CategoryKind
    public let id: String
    public let name: String
    public let totalUAW: Double
    public let totalTransactions: Double
    public let projectCount: Int

    public init(kind: CategoryKind, id: String, name: String, totalUAW: Double, totalTransactions: Double, projectCount: Int) {
        self.kind = kind
        self.id = id
        self.name = name
        self.totalUAW = totalUAW
        self.totalTransactions = totalTransactions
        self.projectCount = projectCount
    }
}
