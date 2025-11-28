import Foundation

public protocol GlobalDateRangeProvider {
    /// Returns the global earliest and latest available dates across the metrics shown.
    /// Return nil if the range cannot be determined yet (e.g., data not loaded).
    func globalDateRange() async -> (start: Date, end: Date)?
}

/// Example stub implementation. Replace with your real data provider.
public struct StubGlobalDateRangeProvider: GlobalDateRangeProvider {
    public init() {}
    public func globalDateRange() async -> (start: Date, end: Date)? {
        // Simulate a known range: last two years to today
        let now = Date()
        let start = Calendar.current.date(byAdding: .year, value: -2, to: now) ?? now
        return (start: Calendar.current.startOfDay(for: start), end: Calendar.current.startOfDay(for: now))
    }
}
