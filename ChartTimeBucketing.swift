import Foundation
import SwiftUI
import Charts

public enum TimeBucket { case day, week, month, quarter }

public struct TimeBucketer {
    public var calendar: Calendar
    public var locale: Locale = Locale(identifier: "en_US_POSIX")

    public init(calendar: Calendar = .current, locale: Locale = Locale(identifier: "en_US_POSIX")) {
        self.calendar = calendar
        self.locale = locale
    }

    public func bucket(from start: Date, to end: Date) -> TimeBucket {
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        if days <= 14 { return .day }
        if days <= 120 { return .week }
        if days <= 420 { return .month }
        return .quarter
    }

    public func bucketStart(for date: Date, bucket: TimeBucket) -> Date {
        switch bucket {
        case .day:
            return calendar.startOfDay(for: date)
        case .week:
            let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
        case .quarter:
            let comps = calendar.dateComponents([.year, .month], from: date)
            guard let month = comps.month, let year = comps.year else { return calendar.startOfDay(for: date) }
            let qStartMonth = ((month - 1) / 3) * 3 + 1
            let dc = DateComponents(year: year, month: qStartMonth, day: 1)
            return calendar.date(from: dc) ?? calendar.startOfDay(for: date)
        }
    }

    public func desiredTickCount(for width: CGFloat, minSpacing: CGFloat = 60) -> Int {
        max(2, Int((width / minSpacing).rounded()))
    }

    public func xAxisMarks(bucket: TimeBucket, desiredCount: Int) -> some AxisContent {
        let lowerMonth: (Date) -> String = { date in
            let df = DateFormatter()
            df.locale = locale
            df.dateFormat = "LLL"
            return df.string(from: date).lowercased()
        }
        switch bucket {
        case .day:
            return AxisMarks(values: .automatic(desiredCount: desiredCount)) { value in
                AxisGridLine()
                if let date = value.as(Date.self) {
                    let df = DateFormatter()
                    df.locale = locale
                    df.dateFormat = "LLL d"
                    Text(df.string(from: date).lowercased())
                }
            }
        case .week:
            return AxisMarks(values: .automatic(desiredCount: desiredCount)) { value in
                AxisGridLine()
                if let date = value.as(Date.self) {
                    let start = bucketStart(for: date, bucket: .week)
                    let df = DateFormatter()
                    df.locale = locale
                    df.dateFormat = "LLL d"
                    Text(df.string(from: start).lowercased())
                }
            }
        case .month:
            return AxisMarks(values: .automatic(desiredCount: desiredCount)) { value in
                AxisGridLine()
                if let date = value.as(Date.self) { Text(lowerMonth(date)) }
            }
        case .quarter:
            return AxisMarks(values: .automatic(desiredCount: min(desiredCount, 4))) { value in
                AxisGridLine()
                if let date = value.as(Date.self) {
                    let comps = calendar.dateComponents([.month], from: date)
                    if let m = comps.month {
                        let q = ((m - 1) / 3) + 1
                        Text("Q\(q)")
                    }
                }
            }
        }
    }
}
