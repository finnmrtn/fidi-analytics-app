import SwiftUI
import Charts

struct CategoriesView: View {
    @State private var viewModel = CategoriesViewModel()
    @State private var showFilterSheet = false
    @State private var filterViewModel = TimeFilterViewModel()
    @State private var showNetworkSelector = false
    @State private var showCategorySheet0 = false
    @State private var showCategorySheet1 = false
    @State private var showCategorySheet2 = false
    @State private var showCategorySheet3 = false
    @State private var selectedCategoryForSheet: CategoryKind? = nil
    @State private var selectedBackingColor: Color? = nil

    var selectionStore: SharedSelectionStore

    init(viewModel: CategoriesViewModel = CategoriesViewModel(), selectionStore: SharedSelectionStore = SharedSelectionStore()) {
        self._viewModel = State(initialValue: viewModel)
        self.selectionStore = selectionStore
    }
    
    private func mapLocalToShared(_ local: LocalCategoryKindShim) -> CategoryKind {
        switch local {
        case .dex: return .dex
        case .nft: return .nfts
        case .gaming: return .gaming
        case .lending: return .lending
        case .bridge: return .bridges
        case .infrastructure: return .infrastructure
        case .other: return .other
        }
    }
    
    private var topFiltersBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 18))
                Text("Filters")
                    .font(.headline)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.gray.opacity(0.15))
            .clipShape(Capsule())
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(viewModel.selectionLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.gray.opacity(0.15))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var timeFilterLabel: some View {
        let title = Text(viewModel.selectionLabel)
            .font(.subheadline)
            .fontWeight(.semibold)
        return HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.subheadline)
            title
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.gray.opacity(0.15))
        .clipShape(Capsule())
    }
    
    private var selectionLabelText: String {
        if let start = selectionStore.startDate, let end = selectionStore.endDate {
            let f = DateFormatter()
            f.dateFormat = "MMM d, yyyy"
            let sameYear = Calendar.current.component(.year, from: start) == Calendar.current.component(.year, from: end)
            if sameYear {
                let fStart = DateFormatter(); fStart.dateFormat = "MMM d"
                return "\(fStart.string(from: start)) – \(f.string(from: end))"
            } else {
                return "\(f.string(from: start)) – \(f.string(from: end))"
            }
        }
        return "All"
    }

    private var donutCard: some View {
        let slices = viewModel.topThreePlusOtherSlices()
        let totalUAW = slices.reduce(0) { $0 + $1.totalUAW }
        let totalTx = slices.reduce(0) { $0 + $1.totalTransactions }

        return ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)

            VStack(spacing: 12) {
                let indices = Array(0..<slices.count)
                Chart {
                    ForEach(indices, id: \.self) { i in
                        let s = slices[i]
                        SectorMark(
                            angle: .value("UAW", s.totalUAW),
                            innerRadius: .ratio(0.62),
                            outerRadius: .ratio(0.95)
                        )
                        .foregroundStyle(s.color)
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 220)
                .overlay {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left.arrow.right")
                            Text(viewModel.prettyNumber(totalTx))
                        }
                        .font(.headline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 4)

                        HStack(spacing: 8) {
                            Image(systemName: "wallet.pass")
                            Text(viewModel.prettyNumber(totalUAW))
                        }
                        .font(.headline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 4)
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var stackedCategoryCards: some View {
        ZStack(alignment: .bottom) {
            let slices = viewModel.topThreePlusOtherSlices()

            if let c0 = slices[safe: 0] {
                let kind0 = mapLocalToShared(c0.id)
                Button {
                    if let slice = slices.first(where: { $0.id == c0.id }) ?? slices.last {
                        selectedBackingColor = slice.color
                    }
                    selectedCategoryForSheet = kind0
                } label: {
                    StackedMetricCard(
                        title: c0.name,
                        subtitle: "Category",
                        valueText: "",
                        primaryValueIcon: Image("txn_title"),
                        primaryValueText: viewModel.prettyNumber(c0.totalTransactions),
                        secondaryValueIcon: Image("uaw_title"),
                        secondaryValueText: viewModel.prettyNumber(c0.totalUAW),
                        background: AppTheme.StackedCard.CategoriesPerPosition.background(for: 0),
                        iconImage: Image(categoryAssetName(for: c0.id)),
                        iconTint: AppTheme.StackedCard.CategoriesPerPosition.iconTint(for: 0),
                        borderColor: AppTheme.StackedCard.CategoriesPerPosition.border(for: 0),
                        foreground: AppTheme.StackedCard.CategoriesPerPosition.foreground(for: 0),
                        height: 180
                    )
                }
                .buttonStyle(.plain)
                .zIndex(1)
            }

            if let c1 = slices[safe: 1] {
                let kind1 = mapLocalToShared(c1.id)
                Button {
                    if let slice = slices.first(where: { $0.id == c1.id }) ?? slices.last {
                        selectedBackingColor = slice.color
                    }
                    selectedCategoryForSheet = kind1
                } label: {
                    StackedMetricCard(
                        title: c1.name,
                        subtitle: "Category",
                        valueText: "",
                        primaryValueIcon: Image("txn_title"),
                        primaryValueText: viewModel.prettyNumber(c1.totalTransactions),
                        secondaryValueIcon: Image("uaw_title"),
                        secondaryValueText: viewModel.prettyNumber(c1.totalUAW),
                        background: AppTheme.StackedCard.CategoriesPerPosition.background(for: 1),
                        iconImage: Image(categoryAssetName(for: c1.id)),
                        iconTint: AppTheme.StackedCard.CategoriesPerPosition.iconTint(for: 1),
                        borderColor: AppTheme.StackedCard.CategoriesPerPosition.border(for: 1),
                        foreground: AppTheme.StackedCard.CategoriesPerPosition.foreground(for: 1),
                        height: 140
                    )
                }
                .buttonStyle(.plain)
                .zIndex(2)
                .offset(y: 80)
            }

            if let c2 = slices[safe: 2] {
                let kind2 = mapLocalToShared(c2.id)
                Button {
                    if let slice = slices.first(where: { $0.id == c2.id }) ?? slices.last {
                        selectedBackingColor = slice.color
                    }
                    selectedCategoryForSheet = kind2
                } label: {
                    StackedMetricCard(
                        title: c2.name,
                        subtitle: "Category",
                        valueText: "",
                        primaryValueIcon: Image("txn_title"),
                        primaryValueText: viewModel.prettyNumber(c2.totalTransactions),
                        secondaryValueIcon: Image("uaw_title"),
                        secondaryValueText: viewModel.prettyNumber(c2.totalUAW),
                        background: AppTheme.StackedCard.CategoriesPerPosition.background(for: 2),
                        iconImage: Image(categoryAssetName(for: c2.id)),
                        iconTint: AppTheme.StackedCard.CategoriesPerPosition.iconTint(for: 2),
                        borderColor: AppTheme.StackedCard.CategoriesPerPosition.border(for: 2),
                        foreground: AppTheme.StackedCard.CategoriesPerPosition.foreground(for: 2),
                        height: 100
                    )
                }
                .buttonStyle(.plain)
                .zIndex(3)
                .offset(y: 160)
            }

            let other: (name: String, id: LocalCategoryKindShim, totalTransactions: Double, totalUAW: Double, color: Color) = slices.count >= 4 ? slices[3] : (name: "Other", id: .other, totalTransactions: 0.0, totalUAW: 0.0, color: .white)
            let kindOther = mapLocalToShared(other.id)
            Button {
                selectedBackingColor = other.color
                selectedCategoryForSheet = kindOther
            } label: {
                StackedMetricCard(
                    title: other.name,
                    subtitle: "Category",
                    valueText: "",
                    primaryValueIcon: Image("txn_title"),
                    primaryValueText: viewModel.prettyNumber(other.totalTransactions),
                    secondaryValueIcon: Image("uaw_title"),
                    secondaryValueText: viewModel.prettyNumber(other.totalUAW),
                    background: AppTheme.StackedCard.CategoriesPerPosition.background(for: 3),
                    iconImage: Image(categoryAssetName(for: other.id)),
                    iconTint: AppTheme.StackedCard.CategoriesPerPosition.iconTint(for: 3),
                    borderColor: AppTheme.StackedCard.CategoriesPerPosition.border(for: 3),
                    foreground: AppTheme.StackedCard.CategoriesPerPosition.foreground(for: 3),
                    height: 100
                )
            }
            .buttonStyle(.plain)
            .zIndex(4)
            .offset(y: 240)
        }
        .frame(height: 240)
        .padding(.bottom, 140)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        TopNavigation(
                            selectedNetwork: Binding(
                                get: { selectionStore.selectedNetwork },
                                set: { selectionStore.selectedNetwork = $0 }
                            ),
                            showProjectSelector: $showNetworkSelector,
                            showsTimeFilter: true,
                            selectionStore: selectionStore,
                            filterViewModel: filterViewModel,
                            showFilterSheet: $showFilterSheet
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.top, 0)

                        donutCard

                        // Stacked cards for Top 3 + Other categories
                        stackedCategoryCards
                    }
                    .frame(minHeight: proxy.size.height)
                }
            }
            .navigationBarHidden(true)
            .toolbar { }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear {
            // Initialize from shared selection and network
            viewModel.updateNetwork(LocalNetworkShim(rawValue: selectionStore.selectedNetwork.rawValue) ?? .moonbeam)
            viewModel.filterStartDate = selectionStore.startDate
            viewModel.filterEndDate = selectionStore.endDate
            if let agg = selectionStore.selectedAggregation { viewModel.selectedAggregation = agg }
            viewModel.loadData()
#if DEBUG
            let allKinds = CategoryKind.allCases
            for kind in allKinds {
                let name = categoryAssetName(for: kind)
                if UIImage(named: name) == nil {
                    print("[CategoriesView][DEBUG] Missing or misnamed asset: \(name)")
                }
            }
#endif
            if let firstNetwork = Network.allCases.first {
                viewModel.updateNetwork(LocalNetworkShim(rawValue: firstNetwork.rawValue) ?? .moonbeam)
            }
        }
        .onChange(of: selectionStore.selectedNetwork) { _, newNetwork in
            viewModel.updateNetwork(LocalNetworkShim(rawValue: newNetwork.rawValue) ?? .moonbeam)
            viewModel.loadData()
        }
        .onChange(of: selectionStore.startDate) { _, newValue in
            viewModel.filterStartDate = newValue
            viewModel.loadData()
        }
        .onChange(of: selectionStore.endDate) { _, newValue in
            viewModel.filterEndDate = newValue
            viewModel.loadData()
        }
        .onChange(of: selectionStore.selectedAggregation) { _, newValue in
            if let agg = newValue {
                viewModel.selectedAggregation = agg
                viewModel.loadData()
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            TimeFilterView(
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
                globalRangeProvider: StubGlobalDateRangeProvider()
            )
            .standardSheetStyle()
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(item: $selectedCategoryForSheet) { selected in
            CategorySheetContainer(
                selected: selected,
                selectedCategoryForSheet: $selectedCategoryForSheet,
                viewModel: viewModel,
                selectionStore: selectionStore,
                filterViewModel: filterViewModel,
                selectedBackingColor: selectedBackingColor
            )
        }
        .sheet(isPresented: $showNetworkSelector) {
            NavigationStack {
                networkSelectorList
                    .navigationTitle("Select Network")
                    .toolbarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { showNetworkSelector = false } label: { Image(systemName: "xmark") } } }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
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
    
    private func categoryAssetName(for kind: LocalCategoryKindShim) -> String {
        return categoryAssetName(for: mapLocalToShared(kind))
    }

    private func categoryIcon(for kind: CategoryKind) -> String {
        switch kind {
        case .defi: return "chart.line.uptrend.xyaxis"
        case .gaming: return "gamecontroller.fill"
        case .nfts: return "photo.stack.fill"
        case .wallets: return "wallet.pass.fill"
        case .bridges: return "arrow.left.arrow.right"
        case .lending: return "dollarsign.circle.fill"
        case .social: return "person.3.fill"
        case .dex: return "arrow.triangle.swap"
        case .dao: return "person.3.sequence.fill"
        case .depin: return "antenna.radiowaves.left.and.right"
        case .infrastructure: return "cube.fill"
        case .overview: return "square.grid.2x2.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    @ViewBuilder
    private var networkSelectorList: some View {
        List {
            Section("Networks") {
                ForEach(Network.allCases, id: \.self) { network in
                    Button {
                        selectionStore.selectedNetwork = network
                        showNetworkSelector = false
                    } label: {
                        HStack {
                            Text(network.rawValue.capitalized)
                                .foregroundColor(.primary)
                            Spacer()
                            if network == selectionStore.selectedNetwork {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct CategorySheetContainer: View {
    let selected: CategoryKind
    @Binding var selectedCategoryForSheet: CategoryKind?
    let viewModel: CategoriesViewModel
    let selectionStore: SharedSelectionStore
    let filterViewModel: TimeFilterViewModel
    let selectedBackingColor: Color?
    
    private func mapLocalToShared(_ local: LocalCategoryKindShim) -> CategoryKind {
        switch local {
        case .dex: return .dex
        case .nft: return .nfts
        case .gaming: return .gaming
        case .lending: return .lending
        case .bridge: return .bridges
        case .infrastructure: return .infrastructure
        case .other: return .other
        }
    }

    var body: some View {
        let slices = viewModel.topThreePlusOtherSlices()
        let resolvedSlice: (name: String, id: LocalCategoryKindShim, totalTransactions: Double, totalUAW: Double, color: Color) = slices.first(where: { mapLocalToShared($0.id) == selected }) ?? (name: "Other", id: .other, totalTransactions: 0, totalUAW: 0, color: .white)
        let backing = selectedBackingColor ?? resolvedSlice.color
        return CategorieSheet(
            showSheet: Binding(
                get: { selectedCategoryForSheet != nil },
                set: { if !$0 { selectedCategoryForSheet = nil } }
            ),
            category: selected,
            selectionStore: selectionStore,
            filterViewModel: filterViewModel,
            categoriesViewModel: viewModel,
            backingColor: backing
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension CategoriesViewModel {
    static var preview: CategoriesViewModel {
        let vm = CategoriesViewModel()

        if let firstNetwork = Network.allCases.first {
            vm.updateNetwork(LocalNetworkShim(rawValue: firstNetwork.rawValue) ?? .moonbeam)
        }
        // Prefer keeping aggregation stable; default to .sum
        vm.selectedAggregation = .sum
        return vm
    }
}

extension CategoryKind {
    var tintColor: Color {
        switch self {
        case .dex: return Color(hex: "#824500")
        case .nfts: return Color(hex: "#121416")
        case .gaming: return Color(hex: "#2E2E2E")
        case .bridges: return Color(hex: "#824500")
        case .wallets: return Color(hex: "#2E2E2E")
        case .lending: return Color(hex: "#2E2E2E")
        case .social: return Color(hex: "#2E2E2E")
        case .dao: return Color(hex: "#2E2E2E")
        case .defi: return Color(hex: "#2E2E2E")
        case .depin: return Color(hex: "#2E2E2E")
        case .infrastructure: return Color(hex: "#2E2E2E")
        case .overview: return .gray
        case .other: return .gray
        }
    }
}
