//
//  GasFeesSheet.swift
//  analytics
//
//  Created by Assistant on 19.11.25.
//

import SwiftUI
@_exported import Foundation

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
        // Fallback to mock projects derived from metrics
        let fallback = mockTopGasFeesByProjectTop10()
        return fallback
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
                    iconTint: Color(hex: "#2F2F2F"),
                    iconStrokeColor: Color(hex: "#DCDEE1"),
                    backgroundColor: Color(hex: "#2F2F2F")
                ) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: "FFFFFF"),)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(hex: "DCDEE1"), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                        .overlay(
                            Group {
                                if dapps.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "chart.bar")
                                            .font(.title2)
                                            .foregroundColor(Color.maintext)
                                        Text("No gas fee data available")
                                            .font(.subheadline)
                                            .foregroundColor(Color.subtext)
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
