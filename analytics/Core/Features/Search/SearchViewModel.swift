import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    
    @Published private(set) var allProjects: [String] = []
    @Published private(set) var filteredProjects: [String] = []
    @Published private(set) var recommendations: [String] = []
    @Published private(set) var suggestions: [String] = []
    @Published private(set) var recentSearches: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    private static let recentsKey = "SearchViewModel.recentSearches"
    
    init() {
        // Populate from shared mock directory items
        let items = mockDirectoryItems()
        allProjects = items.map { $0.name }.sorted()
        
        if let savedRecents = UserDefaults.standard.stringArray(forKey: Self.recentsKey) {
            recentSearches = savedRecents
        }
        
        loadRecommendations()
        
        filteredProjects = filterProjects(text: "")
        
        $searchText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self = self else { return }
                self.filteredProjects = self.filterProjects(text: text)
                let lowercasedText = text.lowercased()
                if lowercasedText.isEmpty {
                    self.suggestions = []
                } else {
                    self.suggestions = self.allProjects.filter { $0.lowercased().contains(lowercasedText) }.prefix(5).map { $0 }
                }
            }
            .store(in: &cancellables)
    }
    
    private func filterProjects(text: String) -> [String] {
        let lowercasedText = text.lowercased()
        return allProjects.filter { project in
            lowercasedText.isEmpty || project.lowercased().contains(lowercasedText)
        }
    }
    
    func selectSuggestion(_ text: String) {
        searchText = text
        addToRecents(text)
    }
    
    func addToRecents(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame })
        recentSearches.insert(trimmed, at: 0)
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        UserDefaults.standard.set(recentSearches, forKey: Self.recentsKey)
    }
    
    private func loadRecommendations() {
        recommendations = Array(allProjects.prefix(10))
    }
}
