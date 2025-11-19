import SwiftUI

struct SearchView: View {
    @State private var searchText: String = ""
    @FocusState private var isFocused: Bool
    @State private var selectedStellaSwap: Bool = false
    @State private var selectedBeamSwap: Bool = false
    
    private let allProjects = [
        "StellaSwap Alpha",
        "Beam Swap Beta",
        "StellaSwap Gamma",
        "Beam Swap Delta",
        "Alpha Project",
        "Beam Swap Epsilon",
        "StellaSwap Zeta",
        "Other Project"
    ]
    
    private var filteredProjects: [String] {
        allProjects.filter { project in
            // Filter by search text
            let matchesSearch = searchText.isEmpty || project.localizedCaseInsensitiveContains(searchText)
            // Filter by selected chips
            let matchesStella = !selectedStellaSwap || project.localizedCaseInsensitiveContains("StellaSwap")
            let matchesBeam = !selectedBeamSwap || project.localizedCaseInsensitiveContains("Beam Swap")
            return matchesSearch && matchesStella && matchesBeam
        }
    }
    
    var body: some View {
        ZStack {
            // Background blur and dim
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Chips
                HStack(spacing: 12) {
                    FilterChip(title: "StellaSwap", isSelected: $selectedStellaSwap)
                    FilterChip(title: "Beam Swap", isSelected: $selectedBeamSwap)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search for projects", text: $searchText)
                        .focused($isFocused)
                        .submitLabel(.search)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            hideKeyboard()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .accessibilityLabel("Clear search text")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                )
                .padding(.horizontal)
                
                // Results list
                List {
                    if filteredProjects.isEmpty {
                        Text("No results")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredProjects, id: \.self) { project in
                            Text(project)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .padding(.bottom,  safeAreaKeyboardPadding())
            .padding(.top, 16)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
        }
    }
    
    private func safeAreaKeyboardPadding() -> CGFloat {
        // Provide padding at bottom for keyboard safe area, fallback to 0
        UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
    }
}

private struct FilterChip: View {
    let title: String
    @Binding var isSelected: Bool
    
    var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                Text(title)
                    .foregroundColor(.primary)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color(.systemBackground).opacity(isSelected ? 0.3 : 0.15))
            )
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
            .preferredColorScheme(.light)
        SearchView()
            .preferredColorScheme(.dark)
    }
}
