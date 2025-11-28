import SwiftUI

struct FilterSheetView: View {
    let filterViewModel: TimeFilterViewModel
    @Binding var selectedAggregation: Aggregation
    @Binding var filterStartDate: Date?
    @Binding var filterEndDate: Date?
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                TimeFilterView(
                    viewModel: filterViewModel,
                    selectedAggregation: $selectedAggregation,
                    chartStartDate: $filterStartDate,
                    chartEndDate: $filterEndDate
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 24)
            }
            .navigationTitle("Time Scale")
            .toolbarTitleDisplayMode(.inline)
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
            #endif
            .onDisappear {
                // When the filter sheet closes, ensure timeframe and dates are aligned
                // NOTE: FilterSheetView does not have access to SharedSelectionStore here.
                // The TimeFilterViewModel.writeToSelectionStore(store) should be called by the presenting view
                // (e.g., AnalyticsView) and will also set the timeframe via store.apply(timeframe:).
            }
        }
    }
}

#Preview("FilterSheetView") {
    @State var agg: Aggregation = .sum
    @State var start: Date? = nil
    @State var end: Date? = nil
    FilterSheetView(
        filterViewModel: TimeFilterViewModel(),
        selectedAggregation: $agg,
        filterStartDate: $start,
        filterEndDate: $end,
        onClose: {}
    )
}
