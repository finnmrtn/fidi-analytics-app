//
//  AggregationRange.swift
//  analytics
//
//  Created by Finn Garrels on 23.10.25.
//

import Foundation

enum Aggregation: String, CaseIterable, Codable, Identifiable {
    case sum = "Sum"
    case med = "Median"
    case avg = "Average"
    case max = "Max"
    case min = "Min"
    var id: String { self.rawValue }
}
