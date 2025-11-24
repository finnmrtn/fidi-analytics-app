//
//  CategoriesViewModel.swift
//  analytics
//
//  Created by Assistant
//

import SwiftUI
import Observation
import Foundation

// Local fallback definition to resolve missing type error
// If a shared TimeAggregation exists elsewhere, remove this and import that module instead.
enum TimeAggregation: String, CaseIterable, Codable, Sendable {
    case daily
    case weekly
    case monthly
    case quarterly
    case yearly
}

/// Local fallback definition to resolve missing type error
/// If a shared Network exists elsewhere, remove this and import that module instead.
enum Network: String, CaseIterable, Codable, Sendable {
    case moonbeam
    case eigenlayer
    case mantle
    case zksync
    case moonriver
    
}

@Observable
class CategoriesViewModel {
    var selectedNetwork: Network = .moonbeam
    var selectedAggregation: TimeAggregation = .monthly
    var filterStartDate: Date?
    var filterEndDate: Date?
    
    // Top categories for the selected network
    var topCategories: [CategoryRollup] = []
    
    // Pie chart data
    var pieChartData: [(name: String, value: Double, color: Color)] = []
    
    init() {
        loadData()
    }
    
    func loadData() {
        topCategories = mockTopCategories(for: selectedNetwork)
        
        // Prepare pie chart data with colors
        let colors: [Color] = [
            Color(hex: "#FDD835"), // Yellow for first
            Color(hex: "#7E88FF"), // Purple for second
            Color(hex: "#C5CBFF"), // Light purple for third
            Color(hex: "#F4F5F8")  // Light gray for Other
        ]
        
        pieChartData = topCategories.enumerated().map { (index: Int, category: CategoryRollup) -> (name: String, value: Double, color: Color) in
            let value: Double = category.totalUAW + category.totalTransactions
            let color: Color = index < colors.count ? colors[index] : Color.gray
            return (name: category.name, value: value, color: color)
        }
    }
    
    func updateNetwork(_ network: Network) {
        selectedNetwork = network
        loadData()
    }
    
    // Get formatted total for display
    var totalUAW: String {
        let total = topCategories.reduce(0) { $0 + $1.totalUAW }
        return formatNumber(total)
    }
    
    var totalTransactions: String {
        let total = topCategories.reduce(0) { $0 + $1.totalTransactions }
        return formatNumber(total)
    }
    
    private func formatNumber(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fk", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

extension Color {
    init(hex hexString: String) {
        var hex = hexString
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
