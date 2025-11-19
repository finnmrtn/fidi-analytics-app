import SwiftUI
import Charts

struct UAWSheet: View {
    var viewModel: AnalyticsViewModel
    @Bindable var filterViewModel: TimeFilterViewModel
    @State private var showFilterSheet = false

    var body: some View {
        WidgetSheet(
            template: template,
            viewModel: viewModel,
            filterViewModel: filterViewModel,
            showFilterSheet: $showFilterSheet
        )
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(24)
        .presentationDragIndicator(.visible)
    }

    private var template: WidgetTemplate {
        let data = uawPoints()
        return WidgetTemplate(
            type: .uaw,
            title: WidgetType.uaw.title,
            aggregationLabel: viewModel.selectedAggregation.rawValue,
            aggregationValue: MetricFormatter.abbreviated(viewModel.aggregatedUAW),
            filterButtonLabel: viewModel.selectedAggregation.rawValue,
            content: {
                AnyView(UAWChart(points: data))
            }
        )
    }

    private func uawPoints() -> [UAWDataPoint] {
        viewModel.filteredDAppMetrics.map { metric in
            UAWDataPoint(date: metric.date, value: metric.dau ?? 0)
        }
    }
}

private struct UAWDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

private struct UAWChart: View {
    let points: [UAWDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart(points) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Wallets", point.value)
                )
                .foregroundStyle(LinearGradient(colors: [Color("GraphColor2", bundle: .main), Color("GraphColor2", bundle: .main).opacity(0.2)], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3))
            }
            .frame(height: 240)
        }
    }
}
