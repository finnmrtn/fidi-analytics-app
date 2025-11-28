import SwiftUI

struct TimeFilterPopupPresenter : ViewModifier {
    @Binding var isPresented: Bool
    @Bindable var viewModel: TimeFilterViewModel
    @Binding var selectedAggregation: Aggregation
    @Binding var chartStartDate: Date?
    @Binding var chartEndDate: Date?
    var selectionStore: SharedSelectionStore? = nil

    public func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        VStack {
                            Spacer()

                            // Popup container
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Time Scale")
                                        .font(.headline)
                                        .padding(.vertical, 10)
                                    Spacer()
                                    Button {
                                        withAnimation(.easeInOut) { isPresented = false }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.body.weight(.semibold))
                                    }
                                    .accessibilityLabel("Close")
                                }
                                .padding(.horizontal, 16)

                                Divider()

                                VStack(spacing: 0) {
                                    TimeFilterView(
                                        viewModel: viewModel,
                                        selectedAggregation: Binding(
                                            get: { selectionStore?.selectedAggregation ?? selectedAggregation },
                                            set: { newValue in
                                                if let _ = selectionStore { selectionStore?.selectedAggregation = newValue }
                                                selectedAggregation = newValue
                                            }
                                        ),
                                        chartStartDate: Binding(
                                            get: { selectionStore?.startDate ?? chartStartDate },
                                            set: { newValue in
                                                if let _ = selectionStore { selectionStore?.startDate = newValue }
                                                chartStartDate = newValue
                                            }
                                        ),
                                        chartEndDate: Binding(
                                            get: { selectionStore?.endDate ?? chartEndDate },
                                            set: { newValue in
                                                if let _ = selectionStore { selectionStore?.endDate = newValue }
                                                chartEndDate = newValue
                                            }
                                        )
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                }
                                .padding(.top, 15)
                                .padding(.bottom, 15)
                            }
                            .frame(maxWidth: 600)
                            .fixedSize(horizontal: false, vertical: true)
                            .background(
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .fill(Color(.backing))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .stroke(Color.highlight, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .onChange(of: selectionStore?.selectedAggregation) { _, _ in
                                withAnimation(.easeInOut) { isPresented = false }
                            }
                            .onChange(of: selectionStore?.startDate) { _, _ in
                                withAnimation(.easeInOut) { isPresented = false }
                            }
                            .onChange(of: selectionStore?.endDate) { _, _ in
                                withAnimation(.easeInOut) { isPresented = false }
                            }
                            .onChange(of: selectedAggregation) { _, _ in
                                // Fallback when no selectionStore is provided
                                withAnimation(.easeInOut) { isPresented = false }
                            }
                            .onChange(of: chartStartDate) { _, _ in
                                withAnimation(.easeInOut) { isPresented = false }
                            }
                            .onChange(of: chartEndDate) { _, _ in
                                withAnimation(.easeInOut) { isPresented = false }
                            }
                        }
                    }
                    .animation(.easeInOut, value: isPresented)
                }
            }
    }
}

extension View {
    func timeFilterPopup(
        isPresented: Binding<Bool>,
        viewModel: TimeFilterViewModel,
        selectedAggregation: Binding<Aggregation>,
        chartStartDate: Binding<Date?>,
        chartEndDate: Binding<Date?>,
        selectionStore: SharedSelectionStore? = nil
    ) -> some View {
        self.modifier(TimeFilterPopupPresenter (
            isPresented: isPresented,
            viewModel: viewModel,
            selectedAggregation: selectedAggregation,
            chartStartDate: chartStartDate,
            chartEndDate: chartEndDate,
            selectionStore: selectionStore
        ))
    }
}

