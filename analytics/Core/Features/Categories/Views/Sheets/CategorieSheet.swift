import SwiftUI

struct CategorieSheet: View {
    @Binding var showSheet: Bool

    // Mode: if `category` is nil -> show category picker (icons)
    // If set -> show details for that category with dynamic backing via MetricSheetTemplate
    var category: CategoryKind? = nil
    var selectionStore: SharedSelectionStore? = nil
    var filterViewModel: TimeFilterViewModel? = nil
    var categoriesViewModel: CategoriesViewModel? = nil

    // Optional color/icon inputs for details mode
    var backingColor: Color? = nil

    // Callback when a category is chosen in picker mode
    var onSelect: (CategoryKind) -> Void = { _ in }

    var body: some View {
        if let category {
            // DETAILS MODE
            CategoryDetailsSheet(
                showSheet: $showSheet,
                category: category,
                selectionStore: selectionStore ?? SharedSelectionStore(),
                filterViewModel: filterViewModel ?? TimeFilterViewModel(),
                backingColor: backingColor,
                viewModel: categoriesViewModel ?? CategoriesViewModel()
            )
        } else {
            // PICKER MODE (Option 2 with icons)
            NavigationStack {
                List {
                    Section("Categories") {
                        ForEach(CategoryKind.allCases, id: \.self) { kind in
                            Button {
                                onSelect(kind)
                                showSheet = false
                            } label: {
                                HStack(spacing: 12) {
                                    let tint = defaultColor(for: kind)
                                    tintedCategoryIcon(named: categoryAssetName(for: kind), tint: tint)
                                        .accessibilityHidden(true)
                                    Text(kindDisplayName(kind))
                                        .foregroundStyle(tint)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Select Category")
                .toolbarTitleDisplayMode(.inline)
                #if os(iOS)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showSheet = false } label: { Image(systemName: "xmark") }
                            .accessibilityLabel("Close")
                    }
                }
                #endif
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
    }
}

// MARK: - Details Sheet (dynamic backing + white table)

// Local fallback for header theming when CardPosition isn't available from elsewhere
private enum CardPosition: Int {
    case one = 0
    case two = 1
    case three = 2
    case four = 3
}

private struct CategoryDetailsSheet: View {
    @Binding var showSheet: Bool
    let category: CategoryKind
    var selectionStore: SharedSelectionStore
    var filterViewModel: TimeFilterViewModel
    var backingColor: Color?
    var viewModel: CategoriesViewModel

    var body: some View {
        // Compute dynamic slice color from mock/example if available
        let color = backingColor ?? defaultColor(for: category)
        let iconName: String = categoryAssetName(for: category)
        let icon = Image(iconName).renderingMode(.template)

        let slices = viewModel.topThreePlusOtherSlices()
        // Map CategoryKind to String id for slice comparison
        let currentSlice = slices.first(where: { String(describing: $0.id) == category.id }) ?? slices.last

        // Determine card index (1,2,3,4) of the current category among top three + other
        let cardIndex: Int = {
            if let currentSlice, let idx = slices.firstIndex(where: { String(describing: $0.id) == String(describing: currentSlice.id) }) {
                return idx
            } else {
                return 3 // Other
            }
        }()

        let position = CardPosition(rawValue: cardIndex) ?? .four
        let headerTints = SheetHeaderTints(
            iconTint: AppTheme.Sheets.CategoriesPerPosition.iconTint(for: cardIndex),
            iconStroke: AppTheme.Sheets.CategoriesPerPosition.iconStroke(for: cardIndex),
            totalsIconTint: AppTheme.Sheets.CategoriesPerPosition.totalsIconTint,
            totalsTextTint: AppTheme.Sheets.CategoriesPerPosition.totalsTextTint,
            titleText: AppTheme.Sheets.CategoriesPerPosition.titleText
        )

        let headerUAW = currentSlice.map { viewModel.prettyNumber($0.totalUAW) }
        let headerTx = currentSlice.map { viewModel.prettyNumber($0.totalTransactions) }

        ZStack {
            // Full-bleed background color for the sheet content
            color
                .ignoresSafeArea()

            VStack(spacing: 0) {
                MetricSheetTemplate(
                    title: "",
                    metric: kindDisplayName(category),
                    metricValue: (currentSlice.map { "UAW: \(viewModel.prettyNumber($0.totalUAW))  ·  TXNs: \(viewModel.prettyNumber($0.totalTransactions))" } ?? ""),
                    filterViewModel: filterViewModel,
                    selectionStore: selectionStore,
                    filterButtonLabel: nil,
                    onClose: { showSheet = false },
                    onOpenFilter: {},
                    icon: icon,
                    iconTint: headerTints.iconTint,
                    iconStrokeColor: headerTints.iconStroke,
                    variant: .categories,
                    headerUAWTotal: headerUAW,
                    headerTxTotal: headerTx,
                    headerTotalsIconTint: headerTints.totalsIconTint,
                    headerTotalsTextTint: headerTints.totalsTextTint,
                    titleTextTint: headerTints.titleText
                ) {
                    VStack(spacing: 8) {
                        // Table content inside white box with 24px corner radius
                        VStack(spacing: 0) {
                            CategoryDetailsContent(category: category, selectionStore: selectionStore, viewModel: viewModel)
                            
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                    }
                   
                }
                .padding(.top, 16)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }
}

private struct SheetHeaderTints {
    let iconTint: Color
    let iconStroke: Color
    let totalsIconTint: Color
    let totalsTextTint: Color
    let titleText: Color
}

private func headerTintsFor(position: CardPosition) -> SheetHeaderTints {
    switch position {
    case .one:
        return SheetHeaderTints(
            iconTint: AppTheme.StackedCards.Categories.Card0.iconTint,
            iconStroke: AppTheme.StackedCards.Categories.Card0.border,
            totalsIconTint: AppTheme.StackedCards.Categories.Card0.iconTint,
            totalsTextTint: AppTheme.textSecondary,
            titleText: AppTheme.textPrimary
        )
    case .two:
        return SheetHeaderTints(
            iconTint: AppTheme.StackedCards.Categories.Card1.iconTint,
            iconStroke: AppTheme.StackedCards.Categories.Card1.border,
            totalsIconTint: AppTheme.StackedCards.Categories.Card1.iconTint,
            totalsTextTint: AppTheme.textSecondary,
            titleText: AppTheme.textPrimary
        )
    case .three:
        return SheetHeaderTints(
            iconTint: AppTheme.StackedCards.Categories.Card2.iconTint,
            iconStroke: AppTheme.StackedCards.Categories.Card2.border,
            totalsIconTint: AppTheme.StackedCards.Categories.Card2.iconTint,
            totalsTextTint: AppTheme.textSecondary,
            titleText: AppTheme.textPrimary
        )
    case .four:
        return SheetHeaderTints(
            iconTint: AppTheme.StackedCards.Categories.Card3.iconTint,
            iconStroke: AppTheme.StackedCards.Categories.Card3.border,
            totalsIconTint: AppTheme.StackedCards.Categories.Card3.iconTint,
            totalsTextTint: AppTheme.textSecondary,
            titleText: AppTheme.textPrimary
        )
    }
}

// MARK: - Helpers reused from other files

@ViewBuilder
private func tintedCategoryIcon(named: String, tint: Color, size: CGSize = CGSize(width: 22, height: 22)) -> some View {
    #if DEBUG
    // Try to load the image; if it fails, show a visible placeholder
    if UIImage(named: named) == nil {
        ZStack {
            Rectangle().fill(Color.red.opacity(0.12))
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    } else {
        Image(named)
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(tint)
            .frame(width: size.width, height: size.height)
    }
    #else
    Image(named)
        .resizable()
        .renderingMode(.template)
        .foregroundStyle(tint)
        .frame(width: size.width, height: size.height)
    #endif
}

private func categoryAssetName(for kind: CategoryKind) -> String {
    switch kind {
    case .bridges: return "bridges"
    case .dao: return "dao"
    case .defi: return "defi"
    case .depin: return "depin"
    case .dex: return "dex"
    case .gaming: return "gaming"
    case .infrastructure: return "infrastructure"
    case .lending: return "lending"
    case .nfts: return "nfts"
    case .other: return "other"
    case .social: return "social"
    case .wallets: return "wallets"
    case .overview: return "other"
    }
}

private func kindDisplayName(_ kind: CategoryKind) -> String {
    // Human-readable display names for each category
    switch kind {
    case .defi: return "DeFi"
    case .gaming: return "Gaming"
    case .nfts: return "NFTs"
    case .dex: return "DEX"
    case .bridges: return "Bridges"
    case .dao: return "DAO"
    case .depin: return "DePIN"
    case .infrastructure: return "Infrastructure"
    case .lending: return "Lending"
    case .social: return "Social"
    case .wallets: return "Wallets"
    case .overview: return "Overview"
    case .other: return "Other"
    }
}

private func defaultColor(for kind: CategoryKind) -> Color {
    // Per-category tint used for icons and text; falls back to BrandColor
    switch kind {
    case .defi: return Color(hex: "#FFD341")
    case .gaming: return Color(hex: "#7E88FF")
    case .nfts: return Color(hex: "#73BAFF")
    case .dex: return Color(hex: "#36D19E")
    case .bridges: return Color(hex: "#FF8A65")
    case .dao: return Color(hex: "#9C27B0")
    case .depin: return Color(hex: "#00BCD4")
    case .infrastructure: return Color(hex: "#90A4AE")
    case .lending: return Color(hex: "#FFCA28")
    case .social: return Color(hex: "#EC407A")
    case .wallets: return Color(hex: "#66BB6A")
    case .overview: return Color(hex: "#DBDEE0")
    case .other: return Color(hex: "#DBDEE0")
    }
}

// Local formatter to avoid cross-file dependency
private func formatNumber(_ value: Double) -> String {
    guard value.isFinite else { return "—" }
    let absValue = abs(value)
    if absValue >= 1_000_000 {
        let scaled = value / 1_000_000
        return scaled.formatted(.number.precision(.fractionLength(0...1))) + "M"
    } else if absValue >= 1_000 {
        let scaled = value / 1_000
        return scaled.formatted(.number.precision(.fractionLength(0...1))) + "k"
    } else {
        return value.formatted(.number.precision(.fractionLength(0)))
    }
}

#Preview {
    StatefulPreviewWrapper(true) { binding in
        CategorieSheet(showSheet: binding, category: CategoryKind.defi, selectionStore: SharedSelectionStore(), filterViewModel: TimeFilterViewModel(), categoriesViewModel: CategoriesViewModel(), backingColor: Color(hex: "#FFD341"))
    }
}

/// A small helper to preview bindings
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}

