import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @FocusState private var isFocused: Bool
    var selectionStore: SharedSelectionStore

    @State private var showProjectSelector: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background behind everything
            Color.clear
                .background(.regularMaterial)
                .ignoresSafeArea()

            VStack(spacing: 6) {
                TopNavigation(
                    selectedNetwork: Binding(
                        get: { selectionStore.selectedNetwork },
                        set: { selectionStore.selectedNetwork = $0 }
                    ),
                    showProjectSelector: $showProjectSelector,
                    showsTimeFilter: false
                )
                .padding(.horizontal, 16)

                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search for projects", text: $viewModel.searchText)
                        .focused($isFocused)
                        .submitLabel(.search)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                            hideKeyboard()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .accessibilityLabel("Clear search text")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                )
                .padding(.horizontal, 16)

                List {
                    if viewModel.searchText.isEmpty {
                        if !viewModel.recommendations.isEmpty {
                            Section("Recommendations") {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(viewModel.recommendations.prefix(4), id: \.self) { name in
                                        HStack {
                                            Button(action: { viewModel.selectSuggestion(name) }) {
                                                Text(name)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(.primary)
                                                    .lineLimit(1)
                                                    .padding(.horizontal,14)
                                                    .padding(.vertical,8)
                                                    .background(
                                                        Capsule(style: .continuous)
                                                            .fill(.thinMaterial)
                                                    )
                                                    .overlay(
                                                        Capsule(style: .continuous)
                                                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                                            Spacer(minLength: 8)
                                        }
                                    }
                                }
                                .padding(.horizontal, 8)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                        }
                        if !viewModel.recentSearches.isEmpty {
                            Section("Recent") {
                                ForEach(viewModel.recentSearches, id: \.self) { name in
                                    Button(name) { viewModel.selectSuggestion(name) }
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    } else {
                        if !viewModel.suggestions.isEmpty {
                            Section("Suggestions") {
                                ForEach(viewModel.suggestions, id: \.self) { name in
                                    Button(name) { viewModel.selectSuggestion(name) }
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    }

                    if !viewModel.searchText.isEmpty {
                        if viewModel.filteredProjects.isEmpty {
                            Text("No results")
                                .foregroundColor(.secondary)
                                .listRowBackground(Color.clear)
                        } else {
                            Section("Results") {
                                ForEach(viewModel.filteredProjects, id: \.self) { project in
                                    Button(project) {
                                        viewModel.addToRecents(project)
                                    }
                                    .listRowBackground(Color.clear)
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .listSectionSpacing(6)
            }
            .padding(.top, 16)
            .padding(.bottom, safeAreaKeyboardPadding())
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .sheet(isPresented: $showProjectSelector) {
            NavigationStack {
                List {
                    Section("Networks") {
                        ForEach(Network.allCases, id: \.self) { network in
                            Button {
                                selectionStore.selectedNetwork = network
                                showProjectSelector = false
                            } label: {
                                HStack {
                                    Text(network.rawValue.capitalized)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if network == selectionStore.selectedNetwork {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Select Network")
                .toolbarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { showProjectSelector = false } label: { Image(systemName: "xmark") } } }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
    }
    
    private func safeAreaKeyboardPadding() -> CGFloat {
        // Provide padding at bottom for keyboard safe area, fallback to 0
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return 0 }
        return window.safeAreaInsets.bottom
    }
}

private extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
