import SwiftUI

extension View {
 
    func standardSheetStyle() -> some View {
        self
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
    }

    func standardSheetStyle(
        detents: Set<PresentationDetent> = [.medium, .large],
        showDragIndicator: Bool = true,
        cornerRadius: CGFloat = 24
    ) -> some View {
        self
            .presentationDetents(detents)
            .presentationDragIndicator(showDragIndicator ? .visible : .hidden)
            .presentationCornerRadius(cornerRadius)
    }

    func standardSheetContainer(
        title: String? = nil,
        onClose: (() -> Void)? = nil
    ) -> some View {
        NavigationStack {
            self
                .navigationTitle(title ?? "")
                .toolbarTitleDisplayMode(.inline)
                #if os(iOS)
                .toolbar {
                    if let onClose {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: onClose) {
                                Image(systemName: "xmark")
                            }
                            .accessibilityLabel("Close")
                        }
                    }
                }
                #endif
        }
    }
}
