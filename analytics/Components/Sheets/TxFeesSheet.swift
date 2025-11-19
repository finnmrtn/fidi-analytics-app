//
//  TxFeesSheet.swift
//  analytics
//
//  Created by Assistant on 27.10.25.
//

import SwiftUI

struct TxFeesSheet: View {
    var viewModel: AnalyticsViewModel
    @Binding var showSheet: Bool
    @Binding var showFilterSheet: Bool
    var filterViewModel: TimeFilterViewModel

    var body: some View {
        MetricBarChartSheet(
            title: "Transaction Fees",
            aggregationLabel: viewModel.selectedAggregation.rawValue,
            aggregationFormattedValue: viewModel.aggregatedValue.formatted(),
            data: viewModel.filteredData,
            xDate: \.date,
            yValue: \.viewCount,
            categoryName: \.category.name,
            colorScale: [
                "Organic": Color("GraphColor1", bundle: .main) ?? .gray,
                "Paid": Color("GraphColor2", bundle: .main) ?? .gray,
                "Referral": Color("GraphColor3", bundle: .main) ?? .gray
            ],
            xStride: .month,
            xLabelFormat: .dateTime.month(.abbreviated),
            close: {
                showSheet = false
            },
            filterButtonLabel: viewModel.selectedAggregation.rawValue,
            onOpenFilter: {
                showFilterSheet = true
            }
        )
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
