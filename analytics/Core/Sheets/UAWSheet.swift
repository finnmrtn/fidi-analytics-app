//
//  UAWSheet.swift
//  analytics
//
//  Created by Finn Garrels on 27.10.25.
//

import SwiftUI
import Charts

struct UAWPoint: Identifiable {
    let id: UUID
    let date: Date
    let value: Double
}

struct UAWSheet: View {
    var viewModel: AnalyticsViewModel
    @Binding var showSheet: Bool
    @Binding var showFilterSheet: Bool
    var filterViewModel: TimeFilterViewModel

    var body: some View {
        let data = viewModel.filteredDAppMetrics.map { UAWPoint(id: $0.id, date: $0.date, value: Double($0.dau ?? 0)) }
        
        Group {
            #if canImport(Charts) && canImport(MetricBarChartSheetModule)
            MetricBarChartSheet(
                title: "Unique Active Wallets",
                aggregationLabel: viewModel.selectedAggregation.rawValue,
                aggregationFormattedValue: viewModel.aggregatedUAW.formatted(),
                data: data,
                xDate: \UAWPoint.date,
                yValue: \UAWPoint.value,
                categoryName: nil,
                colorScale: nil,
                xStride: .month,
                xLabelFormat: .dateTime.month(.abbreviated),
                close: { showSheet = false },
                filterButtonLabel: viewModel.selectedAggregation.rawValue,
                onOpenFilter: { showFilterSheet = true }
            )
            #else
            MetricBarChartSheetFallback(
                title: "Unique Active Wallets",
                aggregationLabel: viewModel.selectedAggregation.rawValue,
                aggregationFormattedValue: viewModel.aggregatedUAW.formatted(),
                data: data,
                close: { showSheet = false },
                filterButtonLabel: viewModel.selectedAggregation.rawValue,
                onOpenFilter: { showFilterSheet = true }
            )
            #endif
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


#if !canImport(MetricBarChartSheetModule)
// Lightweight fallback to keep builds working if MetricBarChartSheet isn't in scope
private struct MetricBarChartSheetFallback: View {
    let title: String
    let aggregationLabel: String
    let aggregationFormattedValue: String
    let data: [UAWPoint]
    let close: () -> Void
    let filterButtonLabel: String
    let onOpenFilter: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: close) {
                    Image(systemName: "xmark")
                }
            }
            HStack {
                Text(aggregationLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(aggregationFormattedValue)
                    .font(.title3.weight(.semibold))
            }
            Chart(data) { point in
                BarMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month))
            }
            HStack {
                Spacer()
                Button(action: onOpenFilter) {
                    HStack(spacing: 8) {
                        Text(filterButtonLabel)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}
#endif
