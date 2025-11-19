//
//  AnalyticsView.swift
//  analytics
//
//  Created by Finn Garrels on 23.10.25.
//

import SwiftUI
import Charts

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}


// MARK: - MainTabView (HIG-compliant Tab Bar)
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AnalyticsView()
                    .navigationBarHidden(false)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                Text("Categories View")
                    .navigationTitle("Categories")
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            }
            .tabItem {
                Label("Categories", systemImage: "square.grid.2x2.fill")
            }
            .tag(1)

            NavigationStack {
                Text("Search")
                    .navigationTitle("Search")
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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

struct AnalyticsView: View {
    @State private var viewModel = AnalyticsViewModel()
    @State private var showFilterSheet = false
    @State private var filterViewModel = TimeFilterViewModel()
    @State private var showChartSheet = false
    @State private var showProjectSelector = false
    @State private var presentedWidget: WidgetType?

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .trailing, spacing: 8) {
                   Spacer()

                   VStack(alignment: .leading, spacing: 8) {
                       HStack {
                           VStack(alignment: .leading, spacing: 2) {
                               Text("GLMR Price (24h)")
                                   .font(.subheadline.weight(.medium))
                                   .foregroundColor(.secondary)
                               Text("$0.06822")
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

                      
                   }
                   .padding(.bottom, 16)

           
                    ZStack(alignment: .bottom) {
                        // Transactions (hinten, ganz unten)
                        AnalyticsCard(
                            iconName: "txn",
                            title: "Transactions",
                            value: "3.343M",
                            background: LinearGradient(colors: [Color(hex: "#7E88FF"), Color(hex: "#7E88FF")],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                            iconTint: .white,
                            height: 180
                        ) {
                            presentedWidget = .transactions
                        }
                        .zIndex(1)

                        // UAW
                        AnalyticsCard(
                            iconName: "uaw",
                            title: "UAW",
                            value: "144.3k",
                            background: LinearGradient(colors: [Color(hex: "#C5CBFF"), Color(hex: "#C5CBFF")],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                            iconTint: .white,
                            height: 140
                        ) {
                            presentedWidget = .uaw
                        }
                        .zIndex(2)
                        .offset(y: 45)

                        // Gas Fees
                        AnalyticsCard(
                            iconName: "gasfee",
                            title: "Gas Fees",
                            value: "3.343M",
                            background: LinearGradient(colors: [Color(hex: "#F4F5F8"), Color(hex: "#E8E9EC")],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                            iconTint: Color(hex: "#3B4A91"),
                            height: 100
                        ) {
                            presentedWidget = .gasFees
                        }
                        .zIndex(3)
                        .offset(y: 90)

                        // Transaction Fees (oben, vorne)
                        AnalyticsCard(
                            iconName: "netzworkfee",
                            title: "Transaction Fees",
                            value: "19,603",
                            background: LinearGradient(colors: [Color.white, Color.white],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                            iconTint: Color(hex: "#FF4245"),
                            height: 60
                        ) {
                            presentedWidget = .txFees
                        }
                        .zIndex(4)
                        .offset(y: 135)
                    }
                    .frame(height: 363)
                    .padding(.bottom, 24)
                }

            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(alignment: .center, spacing: 84) {
                        // Logo links
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

                        // Buttons rechts vom Logo
                        HStack(spacing: 10) {
                            Button {
                                showProjectSelector = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder")
                                    Text("Project")
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.thinMaterial, in: Capsule())
                            }
                            .buttonStyle(.plain)

                            Button {
                                showFilterSheet = true
                            } label: {
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
                                .background(.thinMaterial, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }

            .toolbarBackground(.hidden, for: .navigationBar)

        }
        .onAppear {

            // Validate color assets across platforms without importing UIKit
            #if os(iOS) || os(visionOS)
            let colorNames = [
                "GraphColors/GraphColor1",
                "GraphColors/GraphColor2",
                "GraphColors/GraphColor3"
            ]
            for name in colorNames {
                // Using UIImage for presence check only on iOS/visionOS
                if UIImage(named: name, in: .main, with: nil) == nil {
                    print("⚠️ Warning: Color asset '\(name)' not found!")
                } else {
                    print("✅ Color asset '\(name)' found.")
                }
            }
            #elseif os(macOS)
            let colorNames = [
                "GraphColors/GraphColor1",
                "GraphColors/GraphColor2",
                "GraphColors/GraphColor3"
            ]
            for name in colorNames {
                if NSImage(named: NSImage.Name(name)) == nil {
                    print("⚠️ Warning: Color asset '\(name)' not found!")
                } else {
                    print("✅ Color asset '\(name)' found.")
                }
            }
            #else
            // Fallback: attempt to instantiate SwiftUI Color; cannot reliably detect absence, but we log the attempt
            let colorNames = [
                "GraphColors/GraphColor1",
                "GraphColors/GraphColor2",
                "GraphColors/GraphColor3"
            ]
            for name in colorNames {
                _ = Color(name)
                print("ℹ️ Attempted to load color asset '\(name)'.")
            }
            #endif
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedAggregation)
        .sheet(isPresented: $showFilterSheet) {
            NavigationStack {
                ScrollView {
                    TimeFilterSheet(
                        viewModel: filterViewModel,
                        selectedAggregation: $viewModel.selectedAggregation,
                        chartStartDate: $viewModel.filterStartDate,
                        chartEndDate: $viewModel.filterEndDate
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .navigationTitle("Time Scale")
                .toolbarTitleDisplayMode(.inline)
                #if os(iOS)
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
                #endif
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showChartSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Unique Active Wallets")
                            .font(.headline)
                            .padding(.top, 8)

                        Text("\(viewModel.selectedAggregation.rawValue): \(viewModel.aggregatedValue.formatted())")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Chart(viewModel.filteredData) { item in
                            BarMark(
                                x: .value("Month", item.date, unit: .month),
                                y: .value("Views", item.viewCount),
                                stacking: .standard
                            )
                            .foregroundStyle(by: .value("Category", item.category.name))
                        }
                        .frame(height: 0)
                        .chartLegend(.visible)
                        .chartForegroundStyleScale([
                            "Organic": Color("GraphColor1", bundle: .main) ?? .gray,
                            "Paid": Color("GraphColor2", bundle: .main) ?? .gray,
                            "Referral": Color("GraphColor3", bundle: .main) ?? .gray
                        ])
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) {
                                AxisValueLabel(format: .dateTime.month(.abbreviated))
                                AxisGridLine()
                            }
                        }
                        .chartYAxis {
                            AxisMarks {
                                AxisValueLabel()
                                AxisGridLine()
                            }
                        }
                        .padding(.bottom, 12)
                    }
                    .padding(20)
                }
                .navigationTitle("Chart")
                .toolbarTitleDisplayMode(.inline)
                #if os(iOS)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showChartSheet = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("Close")
                    }
                }
                #endif
            }
            #if os(iOS)
            .sheet(isPresented: $showFilterSheet) {
                NavigationStack {
                    ScrollView {
                        TimeFilterSheet(
                            viewModel: filterViewModel,
                            selectedAggregation: $viewModel.selectedAggregation,
                            chartStartDate: $viewModel.filterStartDate,
                            chartEndDate: $viewModel.filterEndDate
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    .navigationTitle("Time Scale")
                    .toolbarTitleDisplayMode(.inline)
                    #if os(iOS)
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
                    #endif
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    Button {
                        showFilterSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Text(viewModel.selectedAggregation.rawValue)
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
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .zIndex(1000)
            #endif
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showProjectSelector) {
            NavigationStack {
                List {
                    // Placeholder content — replace with your real projects
                    Section("Projects") {
                        Button("Project A") { showProjectSelector = false }
                        Button("Project B") { showProjectSelector = false }
                        Button("Project C") { showProjectSelector = false }
                    }
                }
                .navigationTitle("Select Project")
                .toolbarTitleDisplayMode(.inline)
                #if os(iOS)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showProjectSelector = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("Close")
                    }
                }
                #endif
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .sheet(item: $presentedWidget) { widget in
            sheetView(for: widget)
        }
    }
}

extension AnalyticsView {
    @ViewBuilder
    private func sheetView(for widget: WidgetType) -> some View {
        switch widget {
        case .transactions:
            TransactionsSheet(viewModel: viewModel, filterViewModel: filterViewModel)
        case .uaw:
            UAWSheet(viewModel: viewModel, filterViewModel: filterViewModel)
        case .gasFees:
            GasFeesSheet(viewModel: viewModel, filterViewModel: filterViewModel)
        case .txFees:
            TxFeesSheet(viewModel: viewModel, filterViewModel: filterViewModel)
        }
    }
}
