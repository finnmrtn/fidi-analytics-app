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

}

extension Date {
    static func from(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
