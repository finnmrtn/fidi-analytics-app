//
//  GasFeesSheet.swift
//  analytics
//
//  Created by Assistant on 19.11.25.
//

import SwiftUI

struct GasFeesSheet: View {
    var viewModel: AnalyticsViewModel
    @Binding var showSheet: Bool
    var filterViewModel: TimeFilterViewModel

    @State private var showFilterPopup: Bool = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Gas Fees")
                        .font(.title2.bold())
                    Spacer()
                    Button {
                        showSheet = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Text("This is a placeholder for the Gas Fees sheet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack {
                    Spacer()
                    Button {
                        showFilterPopup = true
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
            }
            .padding(16)
        }
        .timeFilterPopup(
            isPresented: $showFilterPopup,
            viewModel: filterViewModel,
            selectedAggregation: Binding(get: { viewModel.selectedAggregation }, set: { viewModel.selectedAggregation = $0 }),
            chartStartDate: Binding(get: { viewModel.filterStartDate }, set: { viewModel.filterStartDate = $0 }),
            chartEndDate: Binding(get: { viewModel.filterEndDate }, set: { viewModel.filterEndDate = $0 })
        )
    }
}
