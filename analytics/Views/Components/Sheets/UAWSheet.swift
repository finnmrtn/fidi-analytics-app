//
//  UAWSheet.swift
//  analytics
//
//  Created by Finn Garrels on 27.10.25.
//

import SwiftUI
import Charts

struct UAWSheet: View {
    var viewModel: AnalyticsViewModel
    @Binding var showSheet: Bool
    @Binding var showFilterSheet: Bool
    var filterViewModel: TimeFilterViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Unique Active Wallets")
                    .font(.headline)
                    .padding(.top, 8)

                Text("\(viewModel.selectedAggregation.rawValue): \(viewModel.aggregatedUAW.formatted())")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Chart(viewModel.filteredDAppMetrics) { item in
                    BarMark(
                        x: .value("Month", item.date, unit: .month),
                        y: .value("UAW", item.dau ?? 0),
                        stacking: .standard
                    )
                }
                .frame(height: 300)
                .chartLegend(.visible)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks {
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
                .padding(.bottom, 12)
            }
            .padding(20)
            .navigationTitle("Unique Active Wallets")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSheet = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            NavigationStack {
                ScrollView {
                    TimeFilterSheet(
                        viewModel: filterViewModel,
                        selectedAggregation: .constant(viewModel.selectedAggregation),
                        chartStartDate: .constant(viewModel.filterStartDate),
                        chartEndDate: .constant(viewModel.filterEndDate)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .navigationTitle("Time Scale")
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showFilterSheet = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("Close")
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button {
                    showFilterSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Text(viewModel.selectedAggregation.rawValue)
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.down")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(24)
        .presentationDragIndicator(.visible)
    }
}
