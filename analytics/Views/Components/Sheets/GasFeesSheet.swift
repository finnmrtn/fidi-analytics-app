//
//  GasFeesSheet.swift
//  analytics
//
//  Created by Assistant on 27.10.25.
//

import SwiftUI
import Charts

struct BarRowView: View {
    let name: String
    let value: Int
    let color: Color
    let maxValue: Int
    
    var body: some View {
        GeometryReader { geo in
            let fraction = maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) : 0
            let barWidth = fraction * geo.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemGray6))
                    .frame(height: 48)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color)
                    .frame(width: max(48, barWidth), height: 48)
                HStack(spacing: 10) {
                    Rectangle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 3, height: 32)
                        .cornerRadius(2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        Text("\(value.formatted())")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(height: 48)
    }
}

struct GasFeesSheet: View {
    var viewModel: AnalyticsViewModel
    @Binding var showSheet: Bool
    @Binding var showFilterSheet: Bool
    var filterViewModel: TimeFilterViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Gas Fees")
                    .font(.headline)
                    .padding(.top, 8)

                Text("\(viewModel.selectedAggregation.rawValue): \(viewModel.aggregatedTradingFees.formatted())")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Chart(viewModel.filteredDAppMetrics) { item in
                    BarMark(
                        x: .value("Month", item.date, unit: .month),
                        y: .value("Gas Fees", item.tradingFees ?? 0),
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
            }
            .padding(20)
            .navigationTitle("Gas Fees")
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
