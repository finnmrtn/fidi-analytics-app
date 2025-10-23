//
//  TransactionsSheet.swift
//  analytics
//
//  Created by Assistant on 27.10.25.
//

import SwiftUI
import Charts

struct TransactionsSheet: View {
    var viewModel: AnalyticsViewModel
    @Binding var showSheet: Bool
    @Binding var showFilterSheet: Bool
    var filterViewModel: TimeFilterViewModel

    @State private var selectedDate: Date? = nil
    @State private var selectedXPosition: CGFloat? = nil

    private static let longDayMonthYearFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .none
        return df
    }()

    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df
    }()

    private func formatAbbreviated(_ value: Double, asCurrency: Bool = true, currencyCode: String = "USD") -> String {
        let absVal = abs(value)
        let sign = value < 0 ? "-" : ""
        let formatted: String
        switch absVal {
        case 1_000_000_000...:
            formatted = String(format: "%.1fB", absVal / 1_000_000_000)
        case 1_000_000...:
            formatted = String(format: "%.1fM", absVal / 1_000_000)
        case 1_000...:
            formatted = String(format: "%.1fk", absVal / 1_000)
        default:
            formatted = String(format: "%.0f", absVal)
        }
        if asCurrency {
            return sign + "$" + formatted // simple USD prefix; swap later if needed
        } else {
            return sign + formatted
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HeaderView(totalText: formatAbbreviated(viewModel.aggregatedTradingVolume, asCurrency: true))
                    .padding(.top, 8)

                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 8)
                        .overlay(
                            VStack(spacing: 0) {
                                if let selectedDate {
                                    TooltipView(
                                        date: selectedDate,
                                        rows: seriesForDate(selectedDate),
                                        formatValue: { value in
                                            formatAbbreviated(value, asCurrency: true)
                                        },
                                        formatDate: { date in
                                            Self.longDayMonthYearFormatter.string(from: date)
                                        },
                                        formatTime: { date in
                                            Self.timeFormatter.string(from: date)
                                        }
                                    )
                                }
                                TransactionsChart(
                                    selectedDate: $selectedDate,
                                    selectedXPosition: $selectedXPosition,
                                    data: viewModel.filteredDAppMetrics,
                                    valueProvider: metricValue
                                )
                                .frame(height: 280)
                                .padding(.bottom, 8)
                            }
                        )
                }
            }
            .padding(20)
            .navigationTitle("Transactions")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSheet = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            NavigationStack {
                ScrollView {
                    TimeFilterSheet(
                        viewModel: filterViewModel,
                        selectedAggregation: .constant(viewModel.selectedAggregation),
                        chartStartDate: .constant(viewModel.filterStartDate),
                        chartEndDate: .constant(viewModel.filterEndDate)
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
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(24)
        .presentationDragIndicator(.visible)
    }

    private struct HeaderView: View {
        let totalText: String
        var body: some View {
            HStack(alignment: .firstTextBaseline) {
                Text("Transactions")
                    .font(.headline)
                Spacer()
                Text(totalText)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
    }

    private struct TooltipView: View {
        let date: Date
        let rows: [SeriesRow]
        let formatValue: (Double) -> String
        let formatDate: (Date) -> String
        let formatTime: (Date) -> String
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Text(formatDate(date))
                        .font(.footnote.weight(.semibold))
                    Spacer()
                    Text(formatTime(date))
                        .font(.footnote.weight(.semibold))
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(rows) { series in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(series.color)
                                .frame(width: 6, height: 6)
                            Text(series.name)
                                .font(.footnote)
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatValue(series.value))
                                .font(.footnote.weight(.semibold))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
    }

    private struct TransactionsChart: View {
        @Binding var selectedDate: Date?
        @Binding var selectedXPosition: CGFloat?
        let data: [DAppMetric]
        let valueProvider: (DAppMetric) -> Double

        var body: some View {
            Chart(data) { item in
                let y = valueProvider(item)
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Value", y)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color("GraphColor1", bundle: .main).opacity(1))

                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Value", y)
                )
                .opacity(selectedDate == item.date ? 1 : 0)
                .symbolSize(40)
                .foregroundStyle(Color("GraphColor1", bundle: .main))
            }
            .chartLegend(.hidden)
            .chartYScale(domain: .automatic(includesZero: true))
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onChanged { value in
                                    // Compute x relative to the plot area
                                    let plotFrame = geo[proxy.plotAreaFrame]
                                    let localX = value.location.x - plotFrame.origin.x
                                    // Clamp within plot area bounds
                                    let clampedX = max(0, min(localX, plotFrame.size.width))
                                    selectedXPosition = clampedX
                                    // Convert the absolute x in the view's coordinate space to a Date using the plot area's origin
                                    let absoluteX = plotFrame.origin.x + clampedX
                                    if let date: Date = proxy.value(atX: absoluteX, as: Date.self) {
                                        selectedDate = date
                                    }
                                }
                                .onEnded { _ in }
                        )
                        .overlay(alignment: .topLeading) {
                            if let x = selectedXPosition {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 1, height: proxy.plotAreaSize.height)
                                    .offset(x: x)
                            }
                        }
                }
            }
        }
    }

    private func metricValue(_ metric: DAppMetric) -> Double {
        return metric.tradingVolume ?? 0
    }

    // Helper to map API-structured mock data for a given date into series rows
    // Expects each metric item to provide `series: [Series]` where Series has `_id`, `name`, `value`, and an optional color.
    // If color not provided, we derive a stable color from the name via .chartColors hash.
    private func seriesForDate(_ date: Date) -> [SeriesRow] {
        guard let item = viewModel.filteredDAppMetrics.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else {
            return []
        }
        let val = metricValue(item)
        return [SeriesRow(_id: "value", name: "Value", value: val, color: Color("GraphColor1", bundle: .main))]
    }

    // Lightweight row model used for the tooltip
    private struct SeriesRow: Identifiable {
        var id: String { _id }
        let _id: String
        let name: String
        let value: Double
        let color: Color
    }
}

