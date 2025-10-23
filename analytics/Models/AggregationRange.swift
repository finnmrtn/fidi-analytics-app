//
//  AggregationRange.swift
//  analytics
//
//  Created by Finn Garrels on 23.10.25.
//

import Foundation

enum Aggregation: String, CaseIterable, Identifiable {
    case sum = "Sum"
    case med = "Median"
    case avg = "Average"
    case max = "Max"
    case min = "Min"
    var id: String { self.rawValue }
}

enum Range: String, CaseIterable, Identifiable {
    case oneMonth = "1 Month"
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    var id: String { self.rawValue }
}
