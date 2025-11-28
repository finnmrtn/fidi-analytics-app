import SwiftUI

public enum MetricSheetVariant {
    case standard
    case categories
}

public struct MetricSheetTemplate<Content: View>: View {
    @State private var showFilterPopup: Bool = false

 
    var filterViewModel: TimeFilterViewModel
    @ObservedObject var selectionStore: SharedSelectionStore

    // Title at top
    private let title: String
    // Metric label (e.g., "Unique Active Wallets") and formatted value (e.g., "123,456")
    private let metric: String
    private let metricValue: String
    private let headerUAWTotal: String?
    private let headerTxTotal: String?
    private let headerTotalsIconTint: Color?
    private let headerTotalsTextTint: Color?
    private let variant: MetricSheetVariant
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
    private let titleTextTint: Color?
    private let closeButtonTint: Color?
    private let backgroundColor: Color?

    init(
        title: String,
        metric: String,
        metricValue: String,
        filterViewModel: TimeFilterViewModel? = nil,
        selectionStore: SharedSelectionStore,
        filterButtonLabel: String? = nil,
        onClose: @escaping () -> Void,
        onOpenFilter: @escaping () -> Void,
        icon: Image? = nil,
        iconTint: Color = AppTheme.textPrimary,
        iconStrokeColor: Color = AppTheme.borderSubtle,
        variant: MetricSheetVariant = .standard,
        headerUAWTotal: String? = nil,
        headerTxTotal: String? = nil,
        headerTotalsIconTint: Color? = nil,
        headerTotalsTextTint: Color? = nil,
        titleTextTint: Color? = nil,
        closeButtonTint: Color? = nil,
        backgroundColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.metric = metric
        self.metricValue = metricValue
        self.filterViewModel = filterViewModel ?? TimeFilterViewModel()
        self.selectionStore = selectionStore
        self.onClose = onClose
        self.filterButtonLabel = filterButtonLabel ?? metric
        self.onOpenFilter = onOpenFilter
        self.icon = icon
        self.iconTint = iconTint
        self.iconStrokeColor = iconStrokeColor
        self.variant = variant
        self.headerUAWTotal = headerUAWTotal
        self.headerTxTotal = headerTxTotal
        self.headerTotalsIconTint = headerTotalsIconTint
        self.headerTotalsTextTint = headerTotalsTextTint
        self.titleTextTint = titleTextTint
        self.closeButtonTint = closeButtonTint
        self.backgroundColor = backgroundColor
        self.content = content()

        // Removed State initializations for aggregation, startDate, endDate
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
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
                    .overlay(
                        Circle()
                            .strokeBorder(iconStrokeColor, lineWidth: 1.5)
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        // Primary title line
                        Text(title.isEmpty ? metric : title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(titleTextTint ?? iconTint)
                            .lineLimit(1)

                        // Optional totals row
                        if variant == .categories && (headerUAWTotal != nil || headerTxTotal != nil) {
                            let iconTintToUse = headerTotalsIconTint ?? iconTint
                            let textTintToUse = headerTotalsTextTint ?? iconTint

                            HStack(spacing: 14) {
                                if let uaw = headerUAWTotal {
                                    HStack(spacing: 6) {
                                        Image("uaw_title")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 18, height: 18)
                                            .foregroundStyle(iconTintToUse)
                                        Text(uaw)
                                    }
                                }
                                if let tx = headerTxTotal {
                                    HStack(spacing: 6) {
                                        Image("txn_title")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 18, height: 18)
                                            .foregroundStyle(iconTintToUse)
                                        Text(tx)
                                    }
                                }
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(textTintToUse)
                        }
                    }

                    Spacer(minLength: 8)


                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .symbolRenderingMode(.hierarchical)
                            .imageScale(.medium)
                            .foregroundStyle(closeButtonTint ?? titleTextTint ?? iconTint)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(.white.opacity(0.35), lineWidth: 0.5)
                                    .blendMode(.overlay)
                            )
                
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }.padding(.horizontal, 8)


                content
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.bottom, 16)



                HStack {
                    Spacer()
                    TimeSelectorButton(selectionStore: selectionStore, filterViewModel: filterViewModel) {
                        onOpenFilter()
                        showFilterPopup = true
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .toolbarTitleDisplayMode(.inline)
        }
        .ignoresSafeArea(edges: .top)
        .timeFilterPopup(
            isPresented: $showFilterPopup,
            viewModel: filterViewModel,
            selectedAggregation: Binding(
                get: { selectionStore.selectedAggregation ?? .sum },
                set: { selectionStore.selectedAggregation = $0 }
            ),
            chartStartDate: Binding(
                get: { selectionStore.startDate },
                set: { selectionStore.startDate = $0 }
            ),
            chartEndDate: Binding(
                get: { selectionStore.endDate },
                set: { selectionStore.endDate = $0 }
            ),
            selectionStore: selectionStore
        )
    }
}


#Preview("MetricSheetTemplate") {
    MetricSheetTemplate(
        title: "Unique Active Wallets",
        metric: "Unique Active Wallets",
        metricValue: "123,456",
        selectionStore: SharedSelectionStore(),
        onClose: {},
        onOpenFilter: {}
    ) {
        // Placeholder content
        VStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Analytics.backing)
                .frame(height: 200)
                .overlay(
                    Text("Your chart or custom content here")
                        .foregroundStyle(AppTheme.textSecondary)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

