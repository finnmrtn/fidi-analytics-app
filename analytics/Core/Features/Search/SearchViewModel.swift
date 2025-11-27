import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedStellaSwap: Bool = false
    @Published var selectedBeamSwap: Bool = false
    
    @Published private(set) var allProjects: [String] = []
    @Published private(set) var filteredProjects: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init(networks: [Network] = [.moonbeam, .mantle, .eigenlayer, .zksync, .moonriver]) {
        let projects = networks.flatMap { network in
            mockProjectsForNetwork(network)
        }
        allProjects = Array(Set(projects)).sorted()
        filteredProjects = filterProjects(text: searchText, stella: selectedStellaSwap, beam: selectedBeamSwap)
        
        Publishers.CombineLatest3($searchText, $selectedStellaSwap, $selectedBeamSwap)
            .map { [weak self] (text, stella, beam) -> [String] in
                self?.filterProjects(text: text, stella: stella, beam: beam) ?? []
            }
            .assign(to: &$filteredProjects)
    }
    
    private func filterProjects(text: String, stella: Bool, beam: Bool) -> [String] {
        let lowercasedText = text.lowercased()
        return allProjects.filter { project in
            let matchesText = lowercasedText.isEmpty || project.lowercased().contains(lowercasedText)
            let matchesStella = !stella || project.range(of: "StellaSwap", options: .caseInsensitive) != nil
            let matchesBeam = !beam || project.range(of: "Beam Swap", options: .caseInsensitive) != nil
            return matchesText && matchesStella && matchesBeam
        }
    }
}
