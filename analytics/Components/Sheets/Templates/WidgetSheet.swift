import SwiftUI

struct WidgetSheet: View {
    let template: WidgetTemplate
    var viewModel: AnalyticsViewModel
    @Bindable var filterViewModel: TimeFilterViewModel
    @Binding var showFilterSheet: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        MetricSheetTemplate(
            title: template.title,
            aggregationLabel: template.aggregationLabel,
            aggregationFormattedValue: template.aggregationValue,
            filterButtonLabel: template.filterButtonLabel,
            onClose: { dismiss() },
            onOpenFilter: { showFilterSheet = true }
        ) {
            template.content()
        }
        .sheet(isPresented: $showFilterSheet) {
            NavigationStack {
                ScrollView {
                    TimeFilterSheet(
                        viewModel: filterViewModel,
                        selectedAggregation: Binding(
                            get: { viewModel.selectedAggregation },
                            set: { viewModel.selectedAggregation = $0 }
                        ),
                        chartStartDate: Binding(
                            get: { viewModel.filterStartDate },
                            set: { viewModel.filterStartDate = $0 }
                        ),
                        chartEndDate: Binding(
                            get: { viewModel.filterEndDate },
                            set: { viewModel.filterEndDate = $0 }
                        )
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .navigationTitle("Time Scale")
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showFilterSheet = false } label: {
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
    }
}
