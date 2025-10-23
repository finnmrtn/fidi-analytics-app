//
//  AnalyticsView.swift
//  analytics
//
//  Created by Finn Garrels on 23.10.25.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @State private var viewModel = AnalyticsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unique Active Wallets")
                .font(.title2.bold())
                .padding(.top)

            // Aggregation Picker
            Picker("Aggregation", selection: $viewModel.selectedAggregation) {
                ForEach(Aggregation.allCases) { agg in
                    Text(agg.rawValue).tag(agg)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 4)

            // Range Picker
            Picker("Range", selection: $viewModel.selectedRange) {
                ForEach(Range.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 12)

            // Total
            Text("\(viewModel.selectedAggregation.rawValue): \(viewModel.aggregatedValue.formatted())")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            // Chart
            Chart(viewModel.filteredData) { item in
                BarMark(
                    x: .value("Month", item.date, unit: .month),
                    y: .value("Views", item.viewCount),
                    stacking: .standard
                )
                .foregroundStyle(by: .value("Category", item.category.name))
            }
            .frame(height: 240)
            .chartLegend(.visible)
            .chartForegroundStyleScale([
                "Organic": Color("GraphColor1", bundle: .main) ?? .gray,
                "Paid": Color("GraphColor2", bundle: .main) ?? .gray,
                "Referral": Color("GraphColor3", bundle: .main) ?? .gray
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) {
                    AxisValueLabel(format: .dateTime.month(.narrow))
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
            .padding(.bottom)

            Spacer()
        }
        .padding(30)
        .onAppear {

            let colorNames = [
                "GraphColors/GraphColor1",
                "GraphColors/GraphColor2",
                "GraphColors/GraphColor3"
            ]
            for name in colorNames {
                if UIColor(named: name) == nil {
                    print("⚠️ Warning: Color asset '\(name)' not found!")
                } else {
                    print("✅ Color asset '\(name)' found.")
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedRange)
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedAggregation)
    }
}
