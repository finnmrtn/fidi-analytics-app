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

    init(viewModel: CategoriesViewModel = CategoriesViewModel()) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Nested PieItem struct for chart data
    private struct PieItem: Identifiable {
        let id = UUID()
        let name: String
        let value: Double
        let color: Color
    }

    // MARK: - Computed property producing 4 slices: top 3 plus Other
    private var topThreePlusOther: [(name: String, id: CategoryKind, totalTransactions: Double, totalUAW: Double, color: Color)] {
        let colors: [Color] = [
            Color(hex: "#FDD835"),
            Color(hex: "#7E88FF"),
            Color(hex: "#73BAFF")
        ]
        let otherColor = Color(hex: "#DBDEE0")

        var slices: [(name: String, id: CategoryKind, totalTransactions: Double, totalUAW: Double, color: Color)] = []

        let categories = viewModel.topCategories

        // Add up to first 3 categories with corresponding colors if available
        for index in 0..<3 {
            if index < categories.count {
                let cat = categories[index]
                slices.append((name: cat.name, id: cat.id, totalTransactions: cat.totalTransactions, totalUAW: cat.totalUAW, color: colors[index]))
            }
        }

        // Sum the rest as Other
        let rest = categories.dropFirst(3)
        let otherTransactions = rest.reduce(0) { $0 + $1.totalTransactions }
        let otherUAW = rest.reduce(0) { $0 + $1.totalUAW }
        // If fewer than 4 total categories, still add Other with 0 totals to keep 4 slices
        slices.append((name: "Other", id: .other, totalTransactions: otherTransactions, totalUAW: otherUAW, color: otherColor))

        return slices
    }

    // MARK: - Pie chart data for Chart view
    private var pieChartData: [PieItem] {
        let sanitized = topThreePlusOther.map { slice in
            let v = slice.totalUAW.isFinite ? max(0, slice.totalUAW) : 0
            return PieItem(name: slice.name, value: v, color: slice.color)
        }
        let total = sanitized.reduce(0) { $0 + $1.value }
        if total == 0 {
            print("[CategoriesView] Pie chart has zero total; showing No Data slice")
            return [PieItem(name: "No Data", value: 1, color: Color(hex: "#DBDEE0"))]
        }
        return sanitized
    }

    var body: some View {
        ZStack(alignment: .top) {
            backgroundLayer

            VStack(spacing: 0) {
                topHeroCard
                    .frame(width: 230, height: 227)
                    .offset(y: -65)
                    .zIndex(10)

                Spacer()
            }
            .onAppear {
                print("[CategoriesView] onAppear - network=\(viewModel.selectedNetwork.rawValue), agg=\(viewModel.selectedAggregation.rawValue), topCategories=\(viewModel.topCategories.count)")
            }

            topFiltersBar
                .offset(y: 10)
                .zIndex(20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    categoryBlock(
                        index: 0,
                        color: Color(hex: "#FDD835"),
                        foreground: Color(red: 0.51, green: 0.27, blue: 0),
                        border: Color(red: 0.51, green: 0.27, blue: 0).opacity(0.15)
                    )
                    .padding(.top, 195)

                    categoryBlock(
                        index: 1,
                        color: Color(hex: "#7E88FF"),
                        foreground: .white,
                        border: Color.white.opacity(0.15)
                    )
                    .padding(.top, 0)

                    categoryBlock(
                        index: 2,
                        color: Color(hex: "#F0F0F0"),
                        foreground: Color(hex: "#2E2E2E"),
                        border: Color(hex: "#73BAFF").opacity(0.15)
                    )
                    .padding(.top, 0)

                    categoryBlock(
                        index: 3,
                        color: .white,
                        foreground: Color(hex: "#2E2E2E"),
                        border: Color(hex: "#DBDEE0")
                    )
                    .padding(.top, 0)

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
            }

            bottomBar
                .frame(height: 72)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .edgesIgnoringSafeArea(.bottom)
                .zIndex(30)
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                principalToolbarContent
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedAggregation)
        .sheet(isPresented: $showFilterSheet) {
            NavigationStack {
                ScrollView {
                    TimeFilterView(
                        viewModel: filterViewModel,
                        selectedAggregation: Binding<Aggregation>(
                            get: { Aggregation(rawValue: viewModel.selectedAggregation.rawValue) ?? Aggregation.allCases.first! },
                            set: { newValue in
                                if let converted = TimeAggregation(rawValue: newValue.rawValue), converted != viewModel.selectedAggregation {
                                    print("[CategoriesView] Changing aggregation to \(converted.rawValue)")
                                    viewModel.selectedAggregation = converted
                                }
                            }
                        ),
                        chartStartDate: Binding<Date>(
                            get: { viewModel.filterStartDate ?? Date() },
                            set: { viewModel.filterStartDate = $0 }
                        ),
                        chartEndDate: Binding<Date>(
                            get: { viewModel.filterEndDate ?? Date() },
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
                        Button {
                            showFilterSheet = false
                        } label: {
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
        .sheet(isPresented: $showNetworkSelector) {
            NavigationStack {
                networkSelectorList
                    .navigationTitle("Select Network")
                    .toolbarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showNetworkSelector = false
                            } label: {
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
        // Category detail sheets
        categorySheet(index: 0, isPresented: $showCategorySheet0)
        categorySheet(index: 1, isPresented: $showCategorySheet1)
        categorySheet(index: 2, isPresented: $showCategorySheet2)
        categorySheet(index: 3, isPresented: $showCategorySheet3)
    }

    // MARK: - New Private Views

    private var backgroundLayer: some View {
        Rectangle()
            .foregroundColor(.white)
            .ignoresSafeArea()
    }

    private var topHeroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(hex: "#F0F0F0"), lineWidth: 0.5)
                )

            HStack(spacing: 32) {
                // Replace static circles with Chart using pieChartData
                Chart(pieChartData) { item in
                    SectorMark(
                        angle: .value("Value", item.value),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
                .frame(width: 220, height: 220)

                VStack(spacing: 16) {
                    statisticPill(
                        iconName: "arrow.left.arrow.right",
                        value: viewModel.totalUAW,
                        color: Color(hex: "#2E2E2E"),
                        pillColor: Color.white.opacity(0.9)
                    )
                    statisticPill(
                        iconName: "doc.text",
                        value: viewModel.totalTransactions,
                        color: Color(hex: "#2E2E2E"),
                        pillColor: Color.white.opacity(0.9)
                    )
                }
                .padding(.trailing, 12)
            }
            .padding(.horizontal, 24)
        }
        .frame(width: 230, height: 227)
    }

    private func statisticPill(iconName: String, value: String, color: Color, pillColor: Color) -> some View {
        // Using system fonts that map to SF Pro by default
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(color.opacity(0.6))
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(pillColor)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var topFiltersBar: some View {
        HStack(spacing: 12) {
            // Left pill - selected network on white background
            HStack(spacing: 6) {
                Image(systemName: "network")
                Text(viewModel.selectedNetwork.rawValue.capitalized)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .onTapGesture {
                showNetworkSelector = true
            }

            // Right pill - selected aggregation (reuse timeFilterLabel but white bg)
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text(viewModel.selectedAggregation.rawValue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: "chevron.down")
                    .font(.caption.bold())
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .onTapGesture {
                showFilterSheet = true
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private func categoryBlock(index: Int, color: Color, foreground: Color, border: Color?) -> some View {
        // Overriding color parameter with topThreePlusOther color if available to ensure consistency with chart slices
        let sliceColor: Color = (index < topThreePlusOther.count) ? topThreePlusOther[index].color : color

        // Use category info from topThreePlusOther to ensure consistency
        let categoryData = (index < topThreePlusOther.count) ? topThreePlusOther[index] : nil
        let categoryName = categoryData?.name ?? "—"
        let categoryId = categoryData?.id ?? .overview
        let transactions = categoryData?.totalTransactions ?? 0
        let uaw = categoryData?.totalUAW ?? 0

        return Button {
            // Only allow sheet for real categories (indices 0...2)
            let count = viewModel.topCategories.count
            guard index >= 0 && index <= 2 && index < count else {
                // index 3 is 'Other' or out of bounds - no action
                print("[CategoriesView] Category tap ignored for index=\(index). topCategories=\(count)")
                return
            }
            print("[CategoriesView] Opening category sheet for index=\(index), name=\(topThreePlusOther[safe: index]?.name ?? "?")")
            switch index {
            case 0: showCategorySheet0 = true
            case 1: showCategorySheet1 = true
            case 2: showCategorySheet2 = true
            default: break
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .strokeBorder(border ?? .clear, lineWidth: 1.5)
                        .background(Circle().fill(sliceColor))
                        .frame(width: 48, height: 48)
                    Image(systemName: categoryIcon(for: categoryId))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(foreground)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(categoryName)
                        .font(.title3.weight(.semibold)) // system font maps to SF Pro by default
                        .foregroundColor(foreground)
                        .lineLimit(1)

                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text")
                                .font(.subheadline.weight(.medium))
                            Text(formatNumber(transactions))
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundColor(foreground.opacity(0.8))

                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.subheadline.weight(.medium))
                            Text(formatNumber(uaw))
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundColor(foreground.opacity(0.8))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .background(sliceColor)
            .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 75, x: 0, y: 15)
        }
        .buttonStyle(.plain)
    }

    private var bottomBar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: -4)

            HStack(spacing: 32) {
                Capsule()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 60, height: 8)

                Spacer()

                Image(systemName: "square.grid.2x2.fill")
                    .font(.title3)
                    .foregroundColor(.gray)

                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 32)
        }
        .padding(.horizontal, 16)
    }


    // MARK: - Helpers to reduce body complexity
    @ViewBuilder
    private func categorySheet(index: Int, isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            if viewModel.topCategories.count > index {
                CategorieCard(
                    category: viewModel.topCategories[index],
                    network: viewModel.selectedNetwork,
                    showSheet: isPresented
                )
            }
        }
    }

    @ViewBuilder
    private var networkSelectorList: some View {
        List {
            Section("Networks") {
                ForEach(Network.allCases, id: \.self) { network in
                    Button {
                        print("[CategoriesView] Selecting network=\(network.rawValue)")
                        viewModel.updateNetwork(network)
                        showNetworkSelector = false
                    } label: {
                        HStack {
                            Text(network.rawValue.capitalized)
                                .foregroundColor(.primary)
                            Spacer()
                            if network == viewModel.selectedNetwork {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
        }
    }

    private var principalToolbarContent: some View {
        HStack(alignment: .center, spacing: 24) {
            appIcon

            HStack(spacing: 10) {
                Button {
                    showNetworkSelector = true
                } label: {
                    networkSelectorLabel
                }
                .buttonStyle(.plain)

                Button {
                    showFilterSheet = true
                } label: {
                    timeFilterLabel
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var appIcon: some View {
        Group {
            if let uiImage = UIImage(named: "FiDi_Logo") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Image(systemName: "app")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .padding(4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var networkSelectorLabel: some View {
        let title = Text(viewModel.selectedNetwork.rawValue.capitalized)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        return HStack(spacing: 6) {
            Image(systemName: "network")
            title
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: Capsule())
    }

    private var timeFilterLabel: some View {
        let title = Text(viewModel.selectedAggregation.rawValue)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        return HStack(spacing: 6) {
            Image(systemName: "calendar")
            title
            Image(systemName: "chevron.down")
                .font(.caption.bold())
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: Capsule())
    }

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
}

// MARK: - Category Card Component
struct CategoryCard: View {
    let category: CategoryRollup
    let background: LinearGradient
    let iconTint: Color
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: categoryIcon(for: category.id))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(iconTint)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(iconTint)

                    if height > 80 {
                        Text("\(category.projectCount) Projects")
                            .font(.caption)
                            .foregroundColor(iconTint.opacity(0.8))
                    }
                }

                Spacer()

                // Stats
                if height > 100 {
                    VStack(alignment: .trailing, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text")
                                .font(.caption)
                            Text(formatNumber(category.totalTransactions))
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(iconTint)

                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.caption)
                            Text(formatNumber(category.totalUAW))
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(iconTint)
                    }
                } else {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.caption)
                            Text(formatNumber(category.totalTransactions))
                                .font(.caption.weight(.semibold))
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.caption)
                            Text(formatNumber(category.totalUAW))
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .foregroundColor(iconTint)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, height > 100 ? 24 : 16)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

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
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension CategoriesViewModel {
    static var preview: CategoriesViewModel {
        let vm = CategoriesViewModel()
        // Set stable defaults to avoid side effects in previews
        if let firstNetwork = Network.allCases.first {
            vm.updateNetwork(firstNetwork)
        }
        // Prefer keeping aggregation stable; if accessible, set to the first case
        if let firstAgg = TimeAggregation.allCases.first {
            vm.selectedAggregation = firstAgg
        }
        return vm
    }
}

#Preview {
    NavigationStack {
        CategoriesView(viewModel: .preview)
    }
}
