import Foundation
import Combine

// Using shared Network from MockData.swift

enum TimePreset: Equatable {
    case oneWeek
    case oneMonth
    case threeMonths
    case oneYear
    case ytd
    case q1, q2, q3, q4
    case all
    case custom
}

final class SharedSelectionStore: ObservableObject {
    @Published var selectedNetwork: Network = .moonbeam
    @Published var selectedAggregation: Aggregation? = nil // default unset; set to a valid Aggregation case elsewhere
    @Published var startDate: Date? = nil
    @Published var endDate: Date? = nil
    @Published var selectedPreset: TimePreset = .all
}

extension SharedSelectionStore {
    func apply(preset: TimePreset, calendar cal: Calendar = .current, now: Date = Date()) {
        selectedPreset = preset

        func startOfQuarter(_ q: Int, year: Int) -> Date? {
            let month = (q - 1) * 3 + 1 // 1, 4, 7, 10
            return cal.date(from: DateComponents(year: year, month: month, day: 1, hour: 12))
        }
        func endOfQuarter(_ q: Int, year: Int) -> Date? {
            let month = q * 3 // 3, 6, 9, 12
            guard let startOfNextMonth = cal.date(from: DateComponents(year: year, month: month + 1, day: 1, hour: 12)),
                  let lastDay = cal.date(byAdding: .day, value: -1, to: startOfNextMonth) else { return nil }
            return lastDay
        }

        switch preset {
        case .oneWeek:
            startDate = cal.date(byAdding: .day, value: -7, to: now)
            endDate = now
        case .oneMonth:
            startDate = cal.date(byAdding: .month, value: -1, to: now)
            endDate = now
        case .threeMonths:
            startDate = cal.date(byAdding: .month, value: -3, to: now)
            endDate = now
        case .oneYear:
            startDate = cal.date(byAdding: .year, value: -1, to: now)
            endDate = now
        case .ytd:
            let y = cal.component(.year, from: now)
            startDate = cal.date(from: DateComponents(year: y, month: 1, day: 1, hour: 12))
            endDate = now
        case .all:
            startDate = nil
            endDate = now
        case .q1, .q2, .q3, .q4:
            let y = cal.component(.year, from: now)
            let q = (preset == .q1 ? 1 : preset == .q2 ? 2 : preset == .q3 ? 3 : 4)
            startDate = startOfQuarter(q, year: y)
            endDate = endOfQuarter(q, year: y)
        case .custom:
            // Custom is managed externally by date pickers
            break
        }
    }
}

extension SharedSelectionStore {
    func apply(scale: TimeFilterViewModel.TimeScale, calendar cal: Calendar = .current, now: Date = Date()) {
        switch scale {
        case .h1:
            startDate = cal.date(byAdding: .hour, value: -1, to: now)
            endDate = now
            selectedPreset = .custom
        case .d1:
            startDate = cal.date(byAdding: .day, value: -1, to: now)
            endDate = now
            selectedPreset = .custom
        case .w1:
            startDate = cal.date(byAdding: .day, value: -6, to: now)
            endDate = now
            selectedPreset = .oneWeek
        case .m1:
            startDate = cal.date(byAdding: .month, value: -1, to: now)
            endDate = now
            selectedPreset = .oneMonth
        case .y1:
            startDate = cal.date(byAdding: .year, value: -1, to: now)
            endDate = now
            selectedPreset = .oneYear
        case .ytd:
            let y = cal.component(.year, from: now)
            startDate = cal.date(from: DateComponents(year: y, month: 1, day: 1, hour: 12))
            endDate = now
            selectedPreset = .ytd
        case .all:
            startDate = nil
            endDate = now
            selectedPreset = .all
        case .q1, .q2, .q3, .q4:
            let y = cal.component(.year, from: now)
            let q: Int = (scale == .q1 ? 1 : scale == .q2 ? 2 : scale == .q3 ? 3 : 4)
            func startOfQuarter(_ q: Int, year: Int) -> Date? {
                let month = (q - 1) * 3 + 1
                return cal.date(from: DateComponents(year: year, month: month, day: 1, hour: 12))
            }
            func endOfQuarter(_ q: Int, year: Int) -> Date? {
                let month = q * 3
                guard let startOfNextMonth = cal.date(from: DateComponents(year: year, month: month + 1, day: 1, hour: 12)),
                      let lastDay = cal.date(byAdding: .day, value: -1, to: startOfNextMonth) else { return nil }
                return lastDay
            }
            startDate = startOfQuarter(q, year: y)
            endDate = endOfQuarter(q, year: y)
            selectedPreset = (q == 1 ? .q1 : q == 2 ? .q2 : q == 3 ? .q3 : .q4)
        }
    }
}
