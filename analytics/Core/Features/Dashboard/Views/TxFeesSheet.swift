//
//  TxFeesSheet.swift
//  analytics
//
//  Created by Assistant on 24.11.25.
//

import SwiftUI

// Minimal stub to resolve reference from AnalyticsView.
// Mirrors the API shape of the other sheets (TransactionsSheet, UAWSheet, GasFeesSheet).
struct TxFeesSheet: View {
    // Keep the same types used by other sheets so it's drop-in compatible
    var viewModel: AnalyticsViewModel
    @Binding var showSheet: Bool
    var filterViewModel: TimeFilterViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Transaction Fees")
                        .font(.title2.weight(.semibold))
                    Spacer()
                    Button {
                        showSheet = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close")
                }

                // Placeholder content; replace with real charts/metrics later
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overview")
                        .font(.headline)
                    Text("This is a placeholder for Transaction Fees analytics.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding(16)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Transaction Fees")
                        .font(.headline)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview("TxFeesSheet") {
    // Provide simple preview with sample bindings
    TxFeesSheet(
        viewModel: AnalyticsViewModel(),
        showSheet: .constant(true),
        filterViewModel: TimeFilterViewModel()
    )
}
