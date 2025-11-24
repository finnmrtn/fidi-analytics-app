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
        case q1 = "1Q"
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

        let start: Date
        let end: Date = now

        switch scale {
        case .h1:
            start = cal.date(byAdding: .hour, value: -1, to: now) ?? now
        case .d1:
            start = cal.startOfDay(for: now)
        case .w1:
            start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now
        case .m1:
            start = cal.date(byAdding: .month, value: -1, to: now) ?? now
        case .q1:
            start = cal.date(byAdding: .month, value: -3, to: now) ?? now
        case .y1:
            start = cal.date(byAdding: .year, value: -1, to: now) ?? now
        case .ytd:
            let comps = cal.dateComponents([.year], from: now)
            start = cal.date(from: DateComponents(year: comps.year, month: 1, day: 1)) ?? cal.startOfDay(for: now)
        case .all:
            // Cap ALL to max 2 years for now
            start = cal.date(byAdding: .year, value: -2, to: now) ?? now
        }

        // Normalize to day boundaries for display consistency
        startDate = cal.startOfDay(for: start)
        endDate = cal.startOfDay(for: end)
    }

    // Apply a custom range from the date picker
    func setCustomRange(start: Date, end: Date, calendar cal: Calendar = .current) {
        let s = cal.startOfDay(for: start)
        let e = cal.startOfDay(for: end)
        startDate = min(s, e)
        endDate = max(s, e)
    }
}

