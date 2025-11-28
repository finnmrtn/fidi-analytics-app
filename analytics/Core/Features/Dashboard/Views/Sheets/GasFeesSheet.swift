//
//  GasFeesSheet.swift
//  analytics
//
//  Created by Assistant on 19.11.25.
//

import SwiftUI

protocol GasFeesDataProviding {
    var topDappsByGasFees: [(name: String, gasFees: Double)] { get }
}

struct GasFeesSheet: View {
    var viewModel: AnalyticsViewModel
    @Binding var showSheet: Bool
    var filterViewModel: TimeFilterViewModel
    var selectionStore: SharedSelectionStore

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
        // Fallback to MockData, also cleaned and sorted for consistency
        let mockData = mockTop10FeesWithNames()
        return mockData
            .map { (name: $0.name, gasFees: $0.tradingFees) }
            .filter { $0.gasFees.isFinite && $0.gasFees >= 0 }
            .sorted { $0.gasFees > $1.gasFees }
            .prefix(10)
            .map { $0 }
    }

    private var totalGasFeesFormatted: String {
        let total = topDappsByGasFees.map { $0.gasFees }.reduce(0, +)
        return total.formatted(.number.notation(.compactName).precision(.fractionLength(0)))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                let dapps = topDappsByGasFees
                
                MetricSheetTemplate(
                    title: "Gas Fees",
                    metric: "Gas Fees",
                    metricValue: totalGasFeesFormatted,
                    filterViewModel: filterViewModel,
                    selectionStore: selectionStore,
                    filterButtonLabel: "Filter",
                    onClose: { showSheet = false },
                    onOpenFilter: { showFilterPopup = true },
                    icon: Image("gasfee"),
                    iconTint: AppTheme.Sheets.GasFees.iconTint,
                    iconStrokeColor: AppTheme.Sheets.GasFees.iconStroke,
                    backgroundColor: AppTheme.Sheets.GasFees.background
                ) {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(AppTheme.Analytics.backing)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(AppTheme.Analytics.shade, lineWidth: 1)
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
                                        RankedChart(dapps: dapps)
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
        }.padding(16)
        
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
                    RankedChart(dapps: dapps)
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
                    RankedChart(dapps: dapps)
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


#if DEBUG
private struct MockFeeItem {
    let name: String
    let tradingFees: Double
}

/// Provides deterministic mock data for previews and fallback paths.
/// Matches the tuple usage `(name: String, tradingFees: Double)` expected by the callers.
private func mockTop10FeesWithNames() -> [MockFeeItem] {
    return [
        MockFeeItem(name: "Project Alpha", tradingFees: 3_343_000),
        MockFeeItem(name: "Project Beta", tradingFees: 1_840_000),
        MockFeeItem(name: "Project Gamma", tradingFees: 450_000),
        MockFeeItem(name: "Delta Swap", tradingFees: 390_000),
        MockFeeItem(name: "Omega Bridge", tradingFees: 320_500),
        MockFeeItem(name: "Zeta Finance", tradingFees: 210_300),
        MockFeeItem(name: "Theta Labs", tradingFees: 180_000),
        MockFeeItem(name: "Sigma Dex", tradingFees: 150_000),
        MockFeeItem(name: "Lambda Pay", tradingFees: 120_000),
        MockFeeItem(name: "Kappa Vault", tradingFees: 95_000),
    ]
}
#endif
