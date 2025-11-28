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
        .padding(8)
    }
}

struct CategoryDetailsTable: View {
    let category: CategoryKind
    var selectionStore: SharedSelectionStore
    var viewModel: CategoriesViewModel

    private func mapCategory(_ c: CategoryKind) -> LocalCategoryKindShim {
        switch c {
        case .dex: return .dex
        case .nfts: return .nft
        case .gaming: return .gaming
        case .lending: return .lending
        case .bridges: return .bridge
        case .infrastructure: return .infrastructure
        default: return .other
        }
    }
    private func mapNetwork(_ n: Network) -> LocalNetworkShim {
        switch n {
        case .moonbeam: return .moonbeam
        case .moonriver: return .moonriver
        case .mantle: return .mantle
        case .eigenlayer: return .eigenlayer
        case .zksync: return .zksync
        default: return .moonbeam
        }
    }

    var body: some View {
        let rows = viewModel.rankedTopProjects(
            for: mapCategory(category),
            on: mapNetwork(selectionStore.selectedNetwork),
            limit: 10
        )

        VStack(spacing: 12) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("#").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).frame(width: 24, alignment: .leading)
                    Text("Name").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    Text("TXNs").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).frame(width: 100, alignment: .trailing)
                    Text("UAW").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
               

                // Rows
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                        HStack {
                            Text("\(idx + 1)").font(.subheadline).foregroundStyle(.secondary).frame(width: 24, alignment: .leading)
                            Text(row.name)
                                .font(.subheadline)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .layoutPriority(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(formatNumber(row.transactions)).font(.subheadline).frame(width: 80, alignment: .trailing)
                            Text(formatNumber(row.uaw)).font(.subheadline).frame(width: 80, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)

                        if idx < rows.count - 1 { Divider().padding(.leading, 12) }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .padding(.top, 8)
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
