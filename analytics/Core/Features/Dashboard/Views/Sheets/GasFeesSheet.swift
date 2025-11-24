//
//  GasFeesSheet.swift
//  analytics
//
//  Created by Assistant on 19.11.25.
//

import SwiftUI
import Charts

protocol GasFeesDataProviding {
    var topDappsByGasFees: [(name: String, gasFees: Double)] { get }
}

private struct GasFeesChart: View {
    let dapps: [(name: String, gasFees: Double)]
    
    private let palette: [Color] = [
        Color("GraphColor2"),      // Blue
        Color("GraphColor5"),      // Yellow
        Color("GraphColor6"),      // Orange
        Color("GraphColor7"),      // Red
        Color("GraphColor4"),      // Pink
        Color("GraphColor3"),      // Purple
        Color("GraphColor1"),      // Green
        Color("GraphColor8"),      // Coral
        Color("GraphColor9"),      // Gray
        Color("GraphColor10")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(dapps.enumerated()), id: \.offset) { index, item in
                let barColor = palette.indices.contains(index) ? palette[index] : palette[index % palette.count]
                
                HorizontalBarRow(
                    name: item.name,
                    value: item.gasFees,
                    color: barColor,
                    maxValue: dapps.map { $0.gasFees }.max() ?? 1
                )
            }
        }
    }
}

private struct HorizontalBarRow: View {
    let name: String
    let value: Double
    let color: Color
    let maxValue: Double
    
    private var barWidthRatio: CGFloat {
        guard maxValue > 0 else { return 0 }
        return CGFloat(value / maxValue)
    }
    
    // Determine if bar is too small to show label inside
    private var isSmallBar: Bool {
        return barWidthRatio < 0.35
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Gray background track
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.shade)
                
                    .frame(height: 48)
                
                // Colored bar section
                HStack(spacing: 0) {
                    // Bar with embedded label for larger bars
                    HStack(spacing: 6) {
                        // 3px color indicator
                        Rectangle()
                            .fill(.white)
                            .frame(width: 3)
                            .cornerRadius(4)
                        
                        if !isSmallBar {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text(value.formatted(.number.notation(.compactName).precision(.fractionLength(0))))
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, isSmallBar ? 0 : 8)
                    .frame(width: geometry.size.width * barWidthRatio, alignment: .leading)
                    .frame(height: 48)
                    .background(color)
                    .cornerRadius(16)
                    
                    // White label box for small bars
                    if isSmallBar {
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(Color(red: 0.94, green: 0.94, blue: 0.94))
                                .frame(width: 3)
                                .cornerRadius(4)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.41, green: 0.41, blue: 0.41))
                                    .lineLimit(1)
                                
                                Text(value.formatted(.number.notation(.compactName).precision(.fractionLength(0))))
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.backing)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white)
                        .cornerRadius(8)
                        .padding(.leading, 10)
                    }
                    
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(height: 48)
        .cornerRadius(4)
    }
}

struct GasFeesSheet: View {
    var viewModel: AnalyticsViewModel
    @Binding var showSheet: Bool
    var filterViewModel: TimeFilterViewModel

    @State private var showFilterPopup: Bool = false

    private var topDappsByGasFees: [(name: String, gasFees: Double)] {
        if let provider = viewModel as? GasFeesDataProviding {
            let cleaned = provider.topDappsByGasFees
                .filter { $0.gasFees.isFinite && $0.gasFees >= 0 }
            if !cleaned.isEmpty {
                let sorted = cleaned.sorted { $0.gasFees > $1.gasFees }
                return Array(sorted.prefix(10))
            }
        }
        // Fallback to MockData
        let mockData = mockTop10FeesWithNames()
        return mockData.map { (name: $0.name, gasFees: $0.tradingFees) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                let rawDapps = topDappsByGasFees
                let dapps = rawDapps.filter { $0.gasFees.isFinite && $0.gasFees >= 0 }
                
                MetricSheetTemplate(
                    title: "Gas Fees",
                    metric: "Gas Fees",
                    metricValue: (dapps.map { $0.gasFees }.reduce(0, +)).formatted(.number.notation(.compactName).precision(.fractionLength(0))),
                    onClose: { showSheet = false },
                    onOpenFilter: { showFilterPopup = true },
                    icon: Image("gasfee")
                ) {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.backing)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.shade, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                        .overlay(
                            Group {
                                if dapps.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "chart.bar")
                                            .font(.title2)
                                            .foregroundColor(.secondary)
                                        Text("No gas fee data available")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding(16)
                                } else {
                                    ScrollView {
                                        GasFeesChart(dapps: dapps)
                                            .padding(8)
                                    }
                                }
                            }
                        )
                        .frame(minHeight: 500, maxHeight: 600)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        
    }
}

// MARK: - Previews

#Preview("Gas Fees Chart - Light") {
    let mockData = mockTop10FeesWithNames()
    let dapps = mockData.map { (name: $0.name, gasFees: $0.tradingFees) }
    
    VStack {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(uiColor: .secondarySystemBackground))
            .overlay(
                ScrollView {
                    GasFeesChart(dapps: dapps)
                        .padding(16)
                }
            )
            .frame(height: 550)
            .padding()
    }
    .preferredColorScheme(.light)
}

#Preview("Gas Fees Chart - Dark") {
    let mockData = mockTop10FeesWithNames()
    let dapps = mockData.map { (name: $0.name, gasFees: $0.tradingFees) }
    
    VStack {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(uiColor: .secondarySystemBackground))
            .overlay(
                ScrollView {
                    GasFeesChart(dapps: dapps)
                        .padding(16)
                }
            )
            .frame(height: 550)
            .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Single Bar Row") {
    VStack(spacing: 8) {
        // Large bar example
        HorizontalBarRow(
            name: "Project Alpha",
            value: 3_343_000,
            color: Color.blue,
            maxValue: 3_343_000
        )
        .padding(.horizontal)
        
        // Medium bar example
        HorizontalBarRow(
            name: "Project Beta",
            value: 184_000,
            color: Color.yellow,
            maxValue: 3_343_000
        )
        .padding(.horizontal)
        
        // Small bar example
        HorizontalBarRow(
            name: "Project Gamma",
            value: 45_000,
            color: Color.orange,
            maxValue: 3_343_000
        )
        .padding(.horizontal)
    }
    .padding()
    .preferredColorScheme(.light)
}

