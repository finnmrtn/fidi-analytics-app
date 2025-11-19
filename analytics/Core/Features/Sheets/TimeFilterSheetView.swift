import SwiftUI

class TimeFilterViewModel {}

enum Aggregation: String {
    case day, week, month, year
}

struct TimeFilterSheetView: View {
    var viewModel: TimeFilterViewModel
    @Binding var selectedAggregation: Aggregation
    @Binding var chartStartDate: Date
    @Binding var chartEndDate: Date

    var body: some View {
        VStack {
            Text("Time Filter Sheet View")
            Text("Selected Aggregation: \(selectedAggregation.rawValue)")
            Text("Start Date: \(chartStartDate.description)")
            Text("End Date: \(chartEndDate.description)")
        }
        .padding()
    }
}

#Preview {
    TimeFilterSheetView(
        viewModel: TimeFilterViewModel(),
        selectedAggregation: .constant(.day),
        chartStartDate: .constant(Date()),
        chartEndDate: .constant(Date())
    )
}
