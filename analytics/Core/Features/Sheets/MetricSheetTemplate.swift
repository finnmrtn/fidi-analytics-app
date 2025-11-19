import SwiftUI

public struct MetricSheetTemplate<Content: View>: View {
    // Title at top
    private let title: String
    // Aggregation label (e.g., "Monthly") and formatted value (e.g., "123,456")
    private let aggregationLabel: String
    private let aggregationFormattedValue: String
    // Content area for chart or custom content
    private let content: Content
    // Close action for the sheet
    private let onClose: () -> Void
    // Filter button label and action
    private let filterButtonLabel: String
    private let onOpenFilter: () -> Void

    public init(
        title: String,
        aggregationLabel: String,
        aggregationFormattedValue: String,
        filterButtonLabel: String,
        onClose: @escaping () -> Void,
        onOpenFilter: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.aggregationLabel = aggregationLabel
        self.aggregationFormattedValue = aggregationFormattedValue
        self.onClose = onClose
        self.filterButtonLabel = filterButtonLabel
        self.onOpenFilter = onOpenFilter
        self.content = content()
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }

                // Aggregation summary
                HStack {
                    Text(aggregationLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(aggregationFormattedValue)
                        .font(.title3.weight(.semibold))
                }

                // Custom content (chart, list, etc.)
                content

                // Filter button row
                HStack {
                    Spacer()
                    Button(action: onOpenFilter) {
                        HStack(spacing: 8) {
                            Text(filterButtonLabel)
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
            .padding(20)
            .navigationTitle(title)
            .toolbarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(24)
        .presentationDragIndicator(.visible)
    }
}
