//
//  TimeFilterViewModel.swift
//  analytics
//
//  Created by Finn Garrels on 27.10.25.
//

import Foundation

@Observable
final class TimeFilterViewModel {
    enum TimeScale: String, CaseIterable, Identifiable {
        case h1 = "1H"
        case d1 = "1D"
        case w1 = "1W"
        case m1 = "1M"
        case q1 = "Q1"
        case q2 = "Q2"
        case q3 = "Q3"
        case q4 = "Q4"
        case y1 = "1Y"
        case ytd = "YTD"
        case all = "ALL"
        var id: String { rawValue }
    }

    // Aktuell ausgewählte Zeitskala
    var selectedScale: TimeScale = .m1

    // Datumsbereich
    var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    var endDate: Date = Date()

    // Apply a preset scale and compute start/end
    func setScale(_ scale: TimeScale, reference now: Date = Date(), calendar cal: Calendar = .current) {
        selectedScale = scale

        var start: Date
        var end: Date = now

        switch scale {
        case .h1:
            start = cal.date(byAdding: .hour, value: -1, to: now) ?? now
        case .d1:
            // Past 1 day ending now
            start = cal.date(byAdding: .day, value: -1, to: now) ?? now
        case .w1:
            // Past 7 days ending now
            start = cal.date(byAdding: .day, value: -6, to: now) ?? now
        case .m1:
            // Past 1 month ending now
            start = cal.date(byAdding: .month, value: -1, to: now) ?? now
        case .q1:
            let year = cal.component(.year, from: now)
            let range = quarterRange(quarter: 1, year: year, calendar: cal)
            startDate = range.start
            endDate = range.end
            selectedScale = scale
            return
        case .q2:
            let year = cal.component(.year, from: now)
            let range = quarterRange(quarter: 2, year: year, calendar: cal)
            startDate = range.start
            endDate = range.end
            selectedScale = scale
            return
        case .q3:
            let year = cal.component(.year, from: now)
            let range = quarterRange(quarter: 3, year: year, calendar: cal)
            startDate = range.start
            endDate = range.end
            selectedScale = scale
            return
        case .q4:
            let year = cal.component(.year, from: now)
            let range = quarterRange(quarter: 4, year: year, calendar: cal)
            startDate = range.start
            endDate = range.end
            selectedScale = scale
            return
        case .y1:
            start = cal.date(byAdding: .year, value: -1, to: now) ?? now
        case .ytd:
            let year = cal.component(.year, from: now)
            start = cal.date(from: DateComponents(year: year, month: 1, day: 1)) ?? cal.startOfDay(for: now)
        case .all:
            // ALL will be set via GlobalDateRangeProvider if available in the UI; fallback to a wide range here
            start = cal.date(byAdding: .year, value: -2, to: now) ?? now
        }

        // Normalize start to day boundary for display consistency; keep end at 'now' for responsiveness
        startDate = cal.startOfDay(for: start)
        endDate = end
    }

    // Apply a custom range from the date picker
    func setCustomRange(start: Date, end: Date, calendar cal: Calendar = .current) {
        let s = cal.startOfDay(for: start)
        let e = cal.startOfDay(for: end)
        startDate = min(s, e)
        endDate = max(s, e)
    }

    // Push current selection to a shared store
    func writeToSelectionStore(_ store: SharedSelectionStore) {
        store.startDate = self.startDate
        store.endDate = self.endDate
    }

    private func quarterRange(quarter: Int, year: Int, calendar cal: Calendar = .current) -> (start: Date, end: Date) {
        let startMonth = (quarter - 1) * 3 + 1
        let start = cal.date(from: DateComponents(year: year, month: startMonth, day: 1)) ?? Date()
        let endMonth = startMonth + 2
        let endDayComponents = DateComponents(year: year, month: endMonth + 1, day: 1)
        let end = cal.date(byAdding: .day, value: -1, to: cal.date(from: endDayComponents) ?? start) ?? start
        return (cal.startOfDay(for: start), cal.startOfDay(for: end))
    }

    // MARK: - Shared formatting helpers
    func presetLabel() -> String {
        let yearSuffix: String = {
            let year = Calendar.current.component(.year, from: endDate) % 100
            return String(format: " '%02d", year)
        }()

        switch selectedScale {
        case .h1: return "1H"
        case .d1: return "1D"
        case .w1: return "1W"
        case .m1: return "1M"
        case .q1: return "Q1" + yearSuffix
        case .q2: return "Q2" + yearSuffix
        case .q3: return "Q3" + yearSuffix
        case .q4: return "Q4" + yearSuffix
        case .y1: return "1Y"
        case .ytd: return "YTD"
        case .all: return "ALL"
        }
    }

    func topBarTitle(aggregation: Aggregation, start: Date?, end: Date?) -> String {
        if let s = start, let e = end {
            let cal = Calendar.current
            let startDay = cal.startOfDay(for: s)
            let endDay = cal.startOfDay(for: e)
            let days = max(1, (cal.dateComponents([.day], from: startDay, to: endDay).day ?? 0) + 1)
            return "\(aggregation.rawValue) / Past \(days)D"
        }
        return "\(aggregation.rawValue) / \(presetLabel())"
    }
}
