//
//  ViewMonthCategory.swift
//  analytics
//
//  Created by Finn Garrels on 23.10.25.
//

import Foundation

struct ViewMonthCategory: Identifiable {
    let id = UUID()
    let date: Date
    let category: ViewCategory
    let viewCount: Int

    static func mockData() -> [ViewMonthCategory] {
        let categories = [
            ViewCategory(name: "Organic", colorName: "GraphBlue"),
            ViewCategory(name: "Paid", colorName: "GraphOrange"),
            ViewCategory(name: "Referral", colorName: "GraphPink")
        ]
        
        var data = [ViewMonthCategory]()
        let baseDate = Date.from(year: 2024, month: 1, day: 1)

        for monthOffset in 0..<12 {
            let date = Calendar.current.date(byAdding: .month, value: monthOffset, to: baseDate)!
            data.append(.init(date: date, category: categories[0], viewCount: Int.random(in: 30_000...80_000)))
            data.append(.init(date: date, category: categories[1], viewCount: Int.random(in: 20_000...60_000)))
            data.append(.init(date: date, category: categories[2], viewCount: Int.random(in: 10_000...40_000)))
        }
        return data
    }
}

extension Date {
    static func from(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
