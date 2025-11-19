import SwiftUI

struct ChartTooltipRow: Identifiable {
    let id = UUID()
    let color: Color
    let name: String
    let value: Double
}

struct ChartTooltip: View {
    let date: Date
    let rows: [ChartTooltipRow]
    let formatValue: (Double) -> String
    let formatDate: (Date) -> String
    let formatTime: (Date) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formatDate(date))
                .font(.footnote)
                .bold()
            Text(formatTime(date))
                .font(.footnote)
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                ForEach(rows) { row in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(row.color)
                            .frame(width: 10, height: 10)
                        Text(row.name)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(formatValue(row.value))
                            .font(.caption)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(radius: 1)
        )
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct ChartTooltip_Previews: PreviewProvider {
    static var previews: some View {
        ChartTooltip(
            date: Date(),
            rows: [
                ChartTooltipRow(color: .red, name: "Revenue", value: 1234.56),
                ChartTooltipRow(color: .green, name: "Expenses", value: 789.01),
                ChartTooltipRow(color: .blue, name: "Profit", value: 445.55)
            ],
            formatValue: { value in String(format: "$%.2f", value) },
            formatDate: { date in
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: date)
            },
            formatTime: { date in
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
