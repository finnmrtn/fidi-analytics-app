import SwiftUI

struct CategorieSheet: View {
    @Binding var showSheet: Bool

    var body: some View {
        NavigationStack {
            List {
                Section("Categories") {
                    Button("All") { showSheet = false }
                    Button("DeFi") { showSheet = false }
                    Button("NFTs") { showSheet = false }
                    Button("Gaming") { showSheet = false }
                }
            }
            .navigationTitle("Select Category")
            .toolbarTitleDisplayMode(.inline)
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSheet = false } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
            }
            #endif
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
}

#Preview {
    StatefulPreviewWrapper(false) { binding in
        CategorieSheet(showSheet: binding)
    }
}

/// A small helper to preview bindings
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
