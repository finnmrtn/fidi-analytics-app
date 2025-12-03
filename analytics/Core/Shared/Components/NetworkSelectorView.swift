import SwiftUI
import Foundation

struct NetworkSelectorView: View {
    @Binding var selectedNetwork: Network
    @Binding var isPresented: Bool

    private var iconTint: Color { .primary }

    var body: some View {
        NavigationStack {
            contentList
                .navigationTitle("Select Network")
                .toolbarTitleDisplayMode(.inline)
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                #if os(iOS)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark").foregroundStyle(Color.subtext)
                        }
                        .accessibilityLabel("Close")
                        .tint(Color.subtext)
                    }
                }
                #endif
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }

    private var contentList: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(Color.module))
            }
            .overlay(
                List {
                    ForEach(Network.allCases, id: \.self) { net in
                        networkRow(for: net)
                            .listRowSeparator(.visible, edges: .all)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .listRowSeparatorTint(Color.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(8)
            )
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func networkRow(for net: Network) -> some View {
        Button {
            selectedNetwork = net
            isPresented = false
        } label: {
            HStack(spacing: 12) {
                iconView(for: net, selected: net == selectedNetwork)
                Text(displayName(for: net))
                    .foregroundColor(.primary)
                Spacer()
                if net == selectedNetwork {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.brand)
                        .font(.system(size: 24, weight: .semibold))
                }
            }
            .padding(.vertical, 4)
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 8))
    }

    private func iconView(for net: Network, selected: Bool) -> some View {
        ZStack {
            networkIcon(for: net)
                .resizable()
                .renderingMode(Image.TemplateRenderingMode.template)
                .foregroundColor(selected ? Color.brand : iconTint)
                .background(selected ? Color.brandShade : Color.backing)
                .scaledToFit()
                .frame(width: 24, height: 24)
             
        }
        .frame(width: 40, height: 40)
        .background(
            Circle().fill(Color.white.opacity(0.0))
        )
        .padding(2)
        .overlay(
            Circle().stroke(Color.shade, lineWidth: 1)
        )
        
    }

    private func displayName(for network: Network) -> String {
        return network.displayName
    }

    private func networkAssetName(for network: Network) -> String {
        switch network {
        case .moonbeam: return "moonbeam"
        case .moonriver: return "moonriver"
        case .mantle: return "mantle"
        case .eigenlayer: return "eigenlayer"
        case .zksync: return "zksync"
        @unknown default: return network.rawValue.lowercased()
        }
    }

    private func networkIcon(for network: Network) -> Image {
        let name = networkAssetName(for: network)
        if UIImage(named: name) != nil {
            return Image(name)
        } else {
            return Image(systemName: "globe")
        }
    }
}

