import Foundation
import SwiftUI

public struct StackedSeriesPart {
    public let name: String
    public let value: Double
    public let color: Color
    public init(name: String, value: Double, color: Color) {
        self.name = name
        self.value = value
        self.color = color
    }
}

public struct StackedSeriesBucket {
    public let date: Date
    public let parts: [StackedSeriesPart]
    public init(date: Date, parts: [StackedSeriesPart]) {
        self.date = date
        self.parts = parts
    }
}

public struct StackedSeriesBuilder<Row, Key: Hashable> {
    public var rows: [Row]
    public var dateOf: (Row) -> Date
    public var keyOf: (Row) -> Key
    public var valueOf: (Row) -> Double
    public var nameForKey: (Key) -> String
    public var colorsForRank: [Color]

    public init(rows: [Row], dateOf: @escaping (Row) -> Date, keyOf: @escaping (Row) -> Key, valueOf: @escaping (Row) -> Double, nameForKey: @escaping (Key) -> String, colorsForRank: [Color]) {
        self.rows = rows
        self.dateOf = dateOf
        self.keyOf = keyOf
        self.valueOf = valueOf
        self.nameForKey = nameForKey
        self.colorsForRank = colorsForRank
    }

    // Build Top-N stacked series for a bucket using a TimeBucketer
    public func buildTopNSeries(topN: Int, bucketer: TimeBucketer, bucket: TimeBucket) -> [StackedSeriesBucket] {
        guard !rows.isEmpty else { return [] }
        // Group by key and compute totals over the entire range
        let grouped = Dictionary(grouping: rows, by: { keyOf($0) })
        let totals: [(key: Key, total: Double)] = grouped.map { (key, group) in
            (key, group.reduce(0) { $0 + valueOf($1) })
        }
        let topKeys = totals.sorted { $0.total > $1.total }.prefix(topN).map { $0.key }
        // Filter rows to top keys only
        let filteredRows = rows.filter { topKeys.contains(keyOf($0)) }
        // Bucket rows by date
        let byBucket = Dictionary(grouping: filteredRows, by: { bucketer.bucketStart(for: dateOf($0), bucket: bucket) })
        let sortedDates = byBucket.keys.sorted()
        // Build parts in rank order with fixed colors
        return sortedDates.map { date in
            let bucketRows = byBucket[date] ?? []
            let perKey: [Key: Double] = Dictionary(grouping: bucketRows, by: { keyOf($0) }).mapValues { group in
                group.reduce(0) { $0 + valueOf($1) }
            }
            let parts: [StackedSeriesPart] = topKeys.enumerated().map { (idx, key) in
                let name = nameForKey(key)
                let value = perKey[key] ?? 0
                let color = colorsForRank[min(idx, colorsForRank.count - 1)]
                return StackedSeriesPart(name: name, value: value, color: color)
            }
            return StackedSeriesBucket(date: date, parts: parts)
        }
    }
}
