//
//  TopNavigation.swift
//  analytics
//
//  Created by Finn Garrels on 24.11.25.
//

import SwiftUI
// Ensure Network enum from shared models is available

struct TopNavigation: View {
    @Binding var selectedNetwork: Network
    @Binding var showProjectSelector: Bool

    // Optional time filter configuration
    var showsTimeFilter: Bool = false
    var selectionStore: SharedSelectionStore? = nil
    var filterViewModel: TimeFilterViewModel? = nil
    var showFilterSheet: Binding<Bool>? = nil

    var body: some View {
        HStack(spacing: 0) {
            Image("fidi")
                .resizable()
                .frame(width: 22, height: 22)
                .padding(.leading, 2)

            Spacer()

            Button(action: { showProjectSelector = true }) {
                HStack(spacing: 8) {
                    Group {
                        #if os(iOS) || os(tvOS) || os(visionOS)
                        if UIImage(named: selectedNetwork.iconName) != nil {
                            Image(selectedNetwork.iconName)
                                .resizable()
                                .renderingMode(.original)
                                .frame(width: 18, height: 18)
                        } else {
                            Image(systemName: "globe")
                                .imageScale(.medium)
                                .foregroundStyle(.secondary)
                        }
                        #elseif os(macOS)
                        if NSImage(named: NSImage.Name(selectedNetwork.iconName)) != nil {
                            Image(selectedNetwork.iconName)
                                .resizable()
                                .renderingMode(.original)
                                .frame(width: 18, height: 18)
                        } else {
                            Image(systemName: "globe")
                                .imageScale(.medium)
                                .foregroundStyle(.secondary)
                        }
                        #else
                        Image(selectedNetwork.iconName)
                            .resizable()
                            .renderingMode(.original)
                            .frame(width: 18, height: 18)
                        #endif
                    }
                    // Removed the Text displaying selectedNetwork.displayName here, always hide it
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground).opacity(0.8))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .onAppear {
                // Apply preselected time range once when showing time filter and no range set yet
                if showsTimeFilter, let selectionStore, let filterViewModel,
                   selectionStore.startDate == nil && selectionStore.endDate == nil {
                    // Use the filterViewModel's currently selected scale
                    filterViewModel.setScale(filterViewModel.selectedScale)
                    selectionStore.startDate = filterViewModel.startDate
                    selectionStore.endDate = filterViewModel.endDate
                }
            }

            if showsTimeFilter, let selectionStore, let filterViewModel, let showFilterSheet {
                Spacer().frame(width: 10)
                TimeSelectorButton(selectionStore: selectionStore, filterViewModel: filterViewModel) {
                    showFilterSheet.wrappedValue = true
                }
            }
        }
    }
}

#Preview("TopNavigation Variants") {
    @State var selected: Network = Network.moonbeam
    @State var showProject = false
    @State var showFilter = false

    let tfvm = TimeFilterViewModel()
    let store = SharedSelectionStore()

    VStack(spacing: 24) {
        // Minimal variant (used e.g. in SearchView)
        NavigationStack {
            TopNavigation(
                selectedNetwork: $selected,
                showProjectSelector: $showProject,
                showsTimeFilter: false
            )
            .padding(.horizontal, 16)
        }
        .frame(height: 60)

        // Full variant with time filter
        NavigationStack {
            TopNavigation(
                selectedNetwork: $selected,
                showProjectSelector: $showProject,
                showsTimeFilter: true,
                selectionStore: store,
                filterViewModel: tfvm,
                showFilterSheet: $showFilter
            )
            .padding(.horizontal, 16)
        }
        .frame(height: 60)
    }
}

