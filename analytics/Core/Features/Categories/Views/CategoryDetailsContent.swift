import SwiftUI

struct CategoryDetailsContent: View {
    let category: CategoryKind
    var selectionStore: SharedSelectionStore
    var viewModel: CategoriesViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Placeholder for future chart content
            CategoryDetailsTable(category: category, selectionStore: selectionStore, viewModel: viewModel)
        }
    }
}

struct CategoryDetailsTable: View {
    let category: CategoryKind
    var selectionStore: SharedSelectionStore
    var viewModel: CategoriesViewModel

    var body: some View {
        let rows: [TopProjectDisplay] = viewModel.rankedTopProjects(
            for: category,
            on: selectionStore.selectedNetwork,
            limit: 10
        )

        VStack(spacing: 12) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("#").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).frame(width: 24, alignment: .leading)
                    Text("Name").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    Text("Transactions").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).frame(width: 110, alignment: .trailing)
                    Text("UAW").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Rows
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                        HStack {
                            Text("\(idx + 1)").font(.subheadline).foregroundStyle(.secondary).frame(width: 24, alignment: .leading)
                            Text(row.name).font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
                            Text(formatNumber(row.transactions)).font(.subheadline).frame(width: 110, alignment: .trailing)
                            Text(formatNumber(row.uaw)).font(.subheadline).frame(width: 80, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)

                        if idx < rows.count - 1 { Divider().padding(.leading, 12) }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
            }
        }
    }
}

// Local formatter to avoid cross-file dependency
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
