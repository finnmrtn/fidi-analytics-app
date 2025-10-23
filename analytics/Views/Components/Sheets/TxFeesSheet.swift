//
//  TxFeesSheet.swift
//  analytics
//
//  Created by Assistant on 27.10.25.
//

import SwiftUI
import Charts

struct TxFeesSheet: View {
    var viewModel: AnalyticsViewModel
    @Binding var showSheet: Bool
    @Binding var showFilterSheet: Bool
    var filterViewModel: TimeFilterViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Transaction Fees")
                    .font(.headline)
                    .padding(.top, 8)

                Text("\(viewModel.selectedAggregation.rawValue): \(viewModel.aggregatedValue.formatted())")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Chart(viewModel.filteredData) { item in
                    BarMark(
                        x: .value("Month", item.date, unit: .month),
                        y: .value("Fees", item.viewCount),
                        stacking: .standard
                    )
                    .foregroundStyle(by: .value("Category", item.category.name))
                }
                .frame(height: 300)
                .chartLegend(.visible)
                .chartForegroundStyleScale([
                    "Organic": Color("GraphColor1", bundle: .main) ?? .gray,
                    "Paid": Color("GraphColor2", bundle: .main) ?? .gray,
                    "Referral": Color("GraphColor3", bundle: .main) ?? .gray
                ])
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
            .navigationTitle("Transaction Fees")
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
