import SwiftUI

struct MetricSheetTemplate<Content: View>: View {
    private let title: String
    private let aggregationLabel: String
    private let aggregationFormattedValue: String
    private let filterButtonLabel: String
    private let onClose: () -> Void
    private let onOpenFilter: () -> Void
    private let content: Content

    init(
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
        self.filterButtonLabel = filterButtonLabel
        self.onClose = onClose
        self.onOpenFilter = onOpenFilter
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                }
                .accessibilityLabel("Close")
            }

            HStack {
                Text(aggregationLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(aggregationFormattedValue)
                    .font(.title3.weight(.semibold))
            }

            content

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
    }
}
