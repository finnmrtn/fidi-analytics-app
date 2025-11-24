//
//  TransactionsSheet.swift
//  analytics
//
//  Created by Assistant on 27.10.25.
//

import SwiftUI
import Charts

// Reusable chart utilities

struct TransactionsSheet: View {
    var viewModel: AnalyticsViewModel
    @Binding var showSheet: Bool
    var filterViewModel: TimeFilterViewModel

    @State private var selectedDate: Date? = nil
    @State private var selectedXPosition: CGFloat? = nil
    @State private var showFilterPopup: Bool = false

    private let bucketer = TimeBucketer()

    private var currentBucket: TimeBucket {
        .day
    }

    // Build stacked series per date for top-10 dapps by aggregated fees over the filtered range
    private var stackedSeries: [(date: Date, parts: [(name: String, value: Double, color: Color)])] {
        // Use filtered metrics from the view model
        let metrics = viewModel.filteredDAppMetrics
        guard !metrics.isEmpty else { return [] }
        
        // Group by dappId to compute top-10 by total fees in range
        let byDapp = Dictionary(grouping: metrics, by: { $0.dappId })
        let directory = mockDirectoryItems()
        let nameById = Dictionary(uniqueKeysWithValues: directory.map { ($0.id, $0.name) })
        
        let totals: [(id: String, name: String, total: Double)] = byDapp.map { (id, rows) in
            let sum = rows.reduce(0) { $0 + ($1.tradingFees ?? 0) }
            return (id, nameById[id] ?? "Project", sum)
        }
        
        // Filter nur DApps mit tatsächlichen Werten > 0
        let top10 = totals.filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
            .prefix(10)
        
        guard !top10.isEmpty else { return [] }
        
        let topIds: [String] = top10.map { $0.id }
        
        // Bucket by the selected granularity for stacked bars
        let byBucket = Dictionary(grouping: metrics.filter { topIds.contains($0.dappId) }, by: { bucketer.bucketStart(for: $0.date, bucket: currentBucket) })
        let sortedKeys = byBucket.keys.sorted()
        
        let series = sortedKeys.compactMap { key -> (date: Date, parts: [(name: String, value: Double, color: Color)])? in
            let rows = byBucket[key] ?? []
            
            // Aggregate per dapp for the bucket
            let perDapp = Dictionary(grouping: rows, by: { $0.dappId }).mapValues { rows in
                rows.reduce(0) { $0 + ($1.tradingFees ?? 0) }
            }
            
            // Map to ordered parts with fixed colors
            let parts: [(String, Double, Color)] = topIds.enumerated().compactMap { (idx, id) in
                let name = nameById[id] ?? "Project"
                let value = perDapp[id] ?? 0
                // Nur Parts mit Wert > 0 einschließen
                guard value > 0 else { return nil }
                let color = ChartTheme.transactionsColors[min(idx, ChartTheme.transactionsColors.count - 1)]
                return (name, value, color)
            }
            
            // Nur Buckets mit mindestens einem Wert zurückgeben
            guard !parts.isEmpty else { return nil }
            return (key, parts)
        }
        
        return series
    }
    
    // Prüfe ob wir gültige Chart-Daten haben
    private var hasValidChartData: Bool {
        let series = stackedSeries
        guard !series.isEmpty else { return false }
        
        // Prüfe ob mindestens ein Datenpunkt mit Wert > 0 existiert
        return series.contains { bucket in
            bucket.parts.contains { $0.value > 0 }
        }
    }

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
            MetricSheetTemplate(
                title: "Transactions",
                metric: "Transactions",
                metricValue: formatAbbreviated(viewModel.aggregatedTradingVolume, asCurrency: true),
                onClose: { showSheet = false },
                onOpenFilter: { showFilterPopup = true },
                icon: Image("txn")
            ) {
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 8)
                        .overlay(
                            VStack(spacing: 0) {
                                if let selectedDate {
                                    ChartTooltip(
                                        date: selectedDate,
                                        rows: seriesForDate(selectedDate).map { ChartTooltipRow(color: $0.color, name: $0.name, value: $0.value) },
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

                                if hasValidChartData {
                                    TransactionsStackedChart(
                                        selectedDate: $selectedDate,
                                        selectedXPosition: $selectedXPosition,
                                        series: stackedSeries.map { (date, parts) in
                                            StackedSeriesPoint(date: date, parts: parts.map { StackedSeriesPart(name: $0.0, value: $0.1, color: $0.2) })
                                        },
                                        bucketer: bucketer,
                                        currentBucket: currentBucket,
                                        style: .stackedArea
                                    )
                                    .frame(height: 280)
                                    .padding(.bottom, 8)
                                } else {
                                    VStack(spacing: 12) {
                                        Image(systemName: "chart.bar.xaxis")
                                            .font(.system(size: 48))
                                            .foregroundStyle(.secondary)
                                        Text("No transaction data available")
                                            .font(.headline)
                                            .foregroundStyle(.secondary)
                                        Text("Select a different time period")
                                            .font(.subheadline)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .frame(height: 280)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        )
                }
            }
        }.padding(16)
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

    private func seriesForDate(_ date: Date) -> [ChartTooltipRow] {
        // Finde den Bucket für das ausgewählte Datum
        let bucketDate = bucketer.bucketStart(for: date, bucket: currentBucket)
        
        guard let bucket = stackedSeries.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: bucketDate)
        }) else {
            return []
        }
        
        return bucket.parts.map { part in
            ChartTooltipRow(color: part.color, name: part.name, value: part.value)
        }
    }
}

