import SwiftUI
import Foundation

struct NetworkSelectorView: View {
    @Binding var selectedNetwork: Network
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List {
                Section("Networks") {
                    ForEach(Network.allCases, id: \.self) { net in
                        Button {
                            selectedNetwork = net
                            isPresented = false
                        } label: {
                            HStack {
                                Text(displayName(for: net))
                                    .foregroundColor(.primary)
                                Spacer()
                                if net == selectedNetwork {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Network")
            .toolbarTitleDisplayMode(.inline)
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
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

    private var accentColor: Color {
        Color(hex: "#7E88FF")
    }

    private func displayName(for network: Network) -> String {
        return network.displayName
    }
}

#Preview("NetworkSelectorView") {
    NetworkSelectorView(
        selectedNetwork: Binding.constant(Network.moonbeam),
        isPresented: Binding.constant(true)
    )
}
