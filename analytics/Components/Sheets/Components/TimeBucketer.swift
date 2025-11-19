import Foundation

enum MetricTimeBucket {
    case day
    case week
    case month
}

struct MetricTimeBucketer {
    private let calendar = Calendar.current

    func bucket(from start: Date, to end: Date) -> MetricTimeBucket {
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        switch days {
        case ..<60:
            return .day
        case ..<365:
            return .week
        default:
            return .month
        }
    }

    func bucketStart(for date: Date, bucket: MetricTimeBucket) -> Date {
        switch bucket {
        case .day:
            return calendar.startOfDay(for: date)
        case .week:
            let weekday = calendar.component(.weekday, from: date)
            let offset = (weekday - calendar.firstWeekday + 7) % 7
            return calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: date)) ?? calendar.startOfDay(for: date)
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
        }
    }
}
