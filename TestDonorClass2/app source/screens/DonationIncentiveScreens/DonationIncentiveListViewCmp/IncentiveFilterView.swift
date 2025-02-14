//
// IncentiveFilterView.swift
// TestDonorClass2
//

import SwiftUI

struct IncentiveFilterView: View {
    @Binding var selectedFilter: DonationIncentiveFilter
    let onFilterChange: () async -> Void
    
    var body: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(DonationIncentiveFilter.allCases, id: \.self) { filter in
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

