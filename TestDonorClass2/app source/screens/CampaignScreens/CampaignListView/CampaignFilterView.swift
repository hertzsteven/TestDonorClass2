import SwiftUI

struct CampaignFilterView: View {
    @Binding var selectedFilter: CampaignFilter
    let onFilterChange: () async -> Void
    
    var body: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(CampaignFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: selectedFilter) { _ in
            Task {
                await onFilterChange()
            }
        }
    }
}

