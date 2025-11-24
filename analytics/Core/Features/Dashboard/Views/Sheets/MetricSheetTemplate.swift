import SwiftUI

public struct MetricSheetTemplate<Content: View>: View {
    @State private var showFilterPopup: Bool = false
    @State private var aggregation: Aggregation = .sum
    @State private var startDate: Date = Date().addingTimeInterval(-7*24*60*60)
    @State private var endDate: Date = Date()

    // Removed var viewModel: TimeFilterViewModel?
    var filterViewModel: TimeFilterViewModel

    // Title at top
    private let title: String
    // Metric label (e.g., "Unique Active Wallets") and formatted value (e.g., "123,456")
    private let metric: String
    private let metricValue: String
    // Content area for chart or custom content
    private let content: Content
    // Close action for the sheet
    private let onClose: () -> Void
    // Filter button label and action
    private let filterButtonLabel: String
    private let onOpenFilter: () -> Void
    // Header icon customization
    private let icon: Image?
    private let iconTint: Color
    private let iconStrokeColor: Color

    init(
        title: String,
        metric: String,
        metricValue: String,
        filterViewModel: TimeFilterViewModel? = nil,
        filterButtonLabel: String? = nil,
        presetAggregation: Aggregation = .sum,
        presetStartDate: Date = Date().addingTimeInterval(-7*24*60*60),
        presetEndDate: Date = Date(),
        onClose: @escaping () -> Void,
        onOpenFilter: @escaping () -> Void,
        icon: Image? = nil,
        iconTint: Color = .primary,
        iconStrokeColor: Color = .white.opacity(0.35),
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.metric = metric
        self.metricValue = metricValue
        self.filterViewModel = filterViewModel ?? TimeFilterViewModel()
        self.onClose = onClose
        self.filterButtonLabel = filterButtonLabel ?? metric
        self.onOpenFilter = onOpenFilter
        self.icon = icon
        self.iconTint = iconTint
        self.iconStrokeColor = iconStrokeColor
        self.content = content()

        self._aggregation = State(initialValue: presetAggregation)
        self._startDate = State(initialValue: presetStartDate)
        self._endDate = State(initialValue: presetEndDate)
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                // Header with glass icon + stacked texts + close
                HStack(alignment: .center, spacing: 12) {
                    
                    ZStack {
                        (icon ?? Image(systemName: "chart.bar.fill"))
                            .renderingMode(.template)
                            .foregroundStyle(iconTint)
                            .imageScale(.medium)
                            .frame(width: 24, height: 24)
                    }
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(iconStrokeColor, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                  

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .symbolRenderingMode(.hierarchical)
                            .imageScale(.medium)
                            .foregroundStyle(.primary)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(.white.opacity(0.35), lineWidth: 0.5)
                                    .blendMode(.overlay)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }

              

                content
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            

            
                HStack {
                    Spacer()
                    Button(action: { onOpenFilter(); showFilterPopup = true }) {
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
            .toolbarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(24)
        .presentationDragIndicator(.visible)
        .timeFilterPopup(
            isPresented: $showFilterPopup,
            viewModel: filterViewModel,
            selectedAggregation: Binding(get: { aggregation }, set: { aggregation = $0 }),
            chartStartDate: Binding(get: { startDate }, set: { if let d = $0 { startDate = d } }),
            chartEndDate: Binding(get: { endDate }, set: { if let d = $0 { endDate = d } })
        )
    }
}


#Preview("MetricSheetTemplate") {
    MetricSheetTemplate(
        title: "Unique Active Wallets",
        metric: "Unique Active Wallets",
        metricValue: "123,456",
        onClose: {},
        onOpenFilter: {}
    ) {
        // Placeholder content
        VStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("Your chart or custom content here")
                        .foregroundStyle(.secondary)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
