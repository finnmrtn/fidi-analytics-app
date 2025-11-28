import SwiftUI

struct TimeSelectorButton: View {
    @ObservedObject var selectionStore: SharedSelectionStore
    var filterViewModel: TimeFilterViewModel
    var action: () -> Void

    init(selectionStore: SharedSelectionStore, filterViewModel: TimeFilterViewModel, action: @escaping () -> Void) {
        self.selectionStore = selectionStore
        self.filterViewModel = filterViewModel
        self.action = action
    }

    private var labelText: String {
        filterViewModel.topBarTitle(
            aggregation: selectionStore.selectedAggregation ?? .sum,
            start: selectionStore.startDate,
            end: selectionStore.endDate
        )
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(labelText)
                    .font(.headline)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(.systemBackground).opacity(0.8))
            )
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview("TimeSelectorButton") {
    TimeSelectorButton(selectionStore: SharedSelectionStore(), filterViewModel: TimeFilterViewModel()) {}
        .padding()
}
