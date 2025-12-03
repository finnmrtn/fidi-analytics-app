//
//  AnalyticsView.swift
//  analytics
//
//  Created by Finn Garrels on 23.09.25.
//
import SwiftUI
import Charts

private struct _SheetSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension View {
    func _measureSheetHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: _SheetSizePreferenceKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(_SheetSizePreferenceKey.self, perform: onChange)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var selectionStore = SharedSelectionStore()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(selectionStore: selectionStore)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                CategoriesView(selectionStore: selectionStore)
            }
            .tabItem {
                Label("Categories", systemImage: "square.grid.2x2.fill")
            }
            .tag(1)

            NavigationStack {
                SearchView(selectionStore: selectionStore)
                    .navigationTitle("Search")
                    .toolbarBackground(.visible, for: .navigationBar)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(2)
        }
        .tint(Color(hex: "#7E88FF"))
        .onChange(of: selectedTab) { _ in
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

struct DashboardView: View {
    @ObservedObject var selectionStore: SharedSelectionStore
    @State private var viewModel = AnalyticsViewModel()
    @State private var showFilterSheet = false
    @State private var filterViewModel = TimeFilterViewModel()
    @State private var showChartSheet = false
    @State private var showProjectSelector = false
    @State private var showTransactionsSheet = false
    @State private var showUAWsheet = false
    @State private var showGasFeesSheet = false
    @State private var showTxFeesSheet = false
    @State private var selectedGLMRPrice: Double? = nil
    @State private var filterSheetHeight: CGFloat = 420

    init(selectionStore: SharedSelectionStore) {
        self.selectionStore = selectionStore
    }

    private func assetPriceSeriesData() -> [(date: Date, price: Double)] {
        let cal = Calendar.current
        let now = Date()
        let start = selectionStore.startDate
        let end = selectionStore.endDate ?? now

        // Derive timeframe once from the window
        let timeframe: Timeframe = {
            guard let s = start else { return .oneMonth }
            let seconds = max(0, end.timeIntervalSince(s))
            if seconds <= 2 * 60 * 60 { return .oneDay }
            if seconds <= 36 * 60 * 60 { return .oneDay }
            if seconds <= 10 * 24 * 60 * 60 { return .oneWeek }
            if seconds <= 45 * 24 * 60 * 60 { return .oneMonth }
            if cal.component(.year, from: s) == cal.component(.year, from: end) { return .ytd }
            if seconds <= 370 * 24 * 60 * 60 { return .oneYear }
            return .all
        }()

        return assetPriceSeries(timeframe: timeframe, calendar: cal, now: end)
    }

    var body: some View {
        let priceSeriesData: Array<(date: Date, price: Double)> = assetPriceSeriesData()
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        TopNavSection(
                            selectedNetwork: Binding(
                                get: { selectionStore.selectedNetwork },
                                set: { selectionStore.selectedNetwork = $0 }
                            ),
                            showProjectSelector: $showProjectSelector,
                            showsTimeFilter: true,
                            selectionStore: selectionStore,
                            filterViewModel: filterViewModel,
                            showFilterSheet: $showFilterSheet
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.top, 0)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Asset Price")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.secondary)
                                    Text(selectedGLMRPrice.map { String(format: "$%.5f", $0) } ?? "$0.06822")
                                        .font(.largeTitle.weight(.medium))
                                        .foregroundColor(.primary)
                                }
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.subheadline.bold())
                                    Text("+42.7%")
                                        .font(.subheadline.bold())
                                }
                                .foregroundColor(.green)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            
                            PriceLineChartView(
                                data: priceSeriesData,
                                startDate: selectionStore.startDate,
                                endDate: selectionStore.endDate
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                    }

                    Spacer(minLength: 0)

                    // Bottom section: stacked cards pinned to bottom
                    BottomCardsSection(
                        showTransactionsSheet: $showTransactionsSheet,
                        showUAWsheet: $showUAWsheet,
                        showGasFeesSheet: $showGasFeesSheet,
                        showTxFeesSheet: $showTxFeesSheet
                    )
                    .frame(height: 240)
                    .padding(.bottom, 140)
                }
                .frame(minHeight: proxy.size.height)
            }
        }
        .onAppear {
            viewModel.selectedAggregation = selectionStore.selectedAggregation ?? .sum
            viewModel.filterStartDate = selectionStore.startDate
            viewModel.filterEndDate = selectionStore.endDate
        }
        .onChange(of: selectionStore.selectedAggregation) { _, newValue in
            viewModel.selectedAggregation = newValue ?? .sum
        }
        .onChange(of: selectionStore.startDate) { _, newValue in
            print("[Filter] startDate ->", newValue as Any)
            viewModel.filterStartDate = newValue
        }
        .onChange(of: selectionStore.endDate) { _, newValue in
            print("[Filter] endDate ->", newValue as Any)
            viewModel.filterEndDate = newValue
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
            .presentationDetents([.height(filterSheetHeight)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showProjectSelector) {
            NetworkSelectorView(
                selectedNetwork: Binding(
                    get: { selectionStore.selectedNetwork },
                    set: { selectionStore.selectedNetwork = $0 }
                ),
                isPresented: $showProjectSelector
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showTransactionsSheet) {
            TransactionsSheet(
                viewModel: viewModel,
                showSheet: $showTransactionsSheet,
                filterViewModel: filterViewModel,
                selectionStore: selectionStore
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showUAWsheet) {
            UAWSheet(
                viewModel: viewModel,
                showSheet: $showUAWsheet,
                filterViewModel: filterViewModel,
                selectionStore: selectionStore
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showGasFeesSheet) {
            GasFeesSheet(
                viewModel: viewModel,
                showSheet: $showGasFeesSheet,
                filterViewModel: filterViewModel,
                selectionStore: selectionStore
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showTxFeesSheet) {
            TransactionFeeSheet(
                viewModel: viewModel,
                showSheet: $showTxFeesSheet,
                filterViewModel: filterViewModel,
                selectionStore: selectionStore
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
    }

    private struct BottomCardsSection: View {
        @Binding var showTransactionsSheet: Bool
        @Binding var showUAWsheet: Bool
        @Binding var showGasFeesSheet: Bool
        @Binding var showTxFeesSheet: Bool

        var body: some View {
            ZStack(alignment: .bottom) {
                Button {
                    showTransactionsSheet = true
                } label: {
                    StackedMetricCard(
                        title: "Transactions",
                        subtitle: "Network",
                        valueText: "3.343M",
                        background: Color.brand,
                        iconImage: Image("txn"),
                        iconTint: Color.white,
                        borderColor: Color.white.opacity(0.15),
                        foreground: Color.maintext,
                        height: 180
                    )
                }
                .buttonStyle(.plain)
                .zIndex(1)
                Button {
                    showUAWsheet = true
                } label: {
                    StackedMetricCard(
                        title: "UAW",
                        subtitle: "Network",
                        valueText: "144.3k",
                        background: Color(hex: "C5CBFF"),
                        iconImage: Image("uaw"),
                        iconTint: Color(hex: "3B4491"),
                        borderColor: Color(hex: "3B4491", alpha: 0.15),
                        foreground: Color(hex: "3B4491"),
                        height: 140
                    )
                }
                .buttonStyle(.plain)
                .zIndex(2)
                .offset(y: 80)

                Button {
                    showGasFeesSheet = true
                } label: {
                    StackedMetricCard(
                        title: "Gas Fees",
                        subtitle: "Network",
                        valueText: "3.343M",
                        background: Color.shade,
                        iconImage: Image("gasfee"),
                        iconTint: Color.subtext,
                        borderColor: Color.highlight,
                        foreground: Color.black,
                        height: 100
                    )
                }
                .buttonStyle(.plain)
                .zIndex(3)
                .offset(y: 160)

                Button {
                    showTxFeesSheet = true
                } label: {
                    StackedMetricCard(
                        title: "Transaction Fees",
                        subtitle: "Network",
                        valueText: "19,603",
                        background: Color.backing,
                        iconImage: Image("networkfee"),
                        iconTint: Color(hex: "#FF4245"),
                        borderColor: Color(hex: "#FF4245", alpha: 0.15),
                        foreground: Color.black,
                        height: 100
                    )
                }
                .buttonStyle(.plain)
                .zIndex(4)
                .offset(y: 240)
            }
        }
    }

    private struct TopNavSection: View {
        @Binding var selectedNetwork: Network
        @Binding var showProjectSelector: Bool
        let showsTimeFilter: Bool
        let selectionStore: SharedSelectionStore
        let filterViewModel: TimeFilterViewModel
        @Binding var showFilterSheet: Bool

        init(
            selectedNetwork: Binding<Network>,
            showProjectSelector: Binding<Bool>,
            showsTimeFilter: Bool,
            selectionStore: SharedSelectionStore,
            filterViewModel: TimeFilterViewModel,
            showFilterSheet: Binding<Bool>
        ) {
            self._selectedNetwork = selectedNetwork
            self._showProjectSelector = showProjectSelector
            self.showsTimeFilter = showsTimeFilter
            self.selectionStore = selectionStore
            self.filterViewModel = filterViewModel
            self._showFilterSheet = showFilterSheet
        }

        var body: some View {
            TopNavigation(
                selectedNetwork: Binding(
                    get: { selectionStore.selectedNetwork },
                    set: { selectionStore.selectedNetwork = $0 }
                ),
                showProjectSelector: $showProjectSelector,
                showsTimeFilter: showsTimeFilter,
                selectionStore: selectionStore,
                filterViewModel: filterViewModel,
                showFilterSheet: $showFilterSheet
            )
        }
    }
}


#Preview("DashboardView") {
    NavigationStack {
        DashboardView(selectionStore: SharedSelectionStore())
    }
}

