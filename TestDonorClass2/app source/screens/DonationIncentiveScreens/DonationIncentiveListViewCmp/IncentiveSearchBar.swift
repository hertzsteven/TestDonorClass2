//
// IncentiveSearchBar.swift
// TestDonorClass2
//

import SwiftUI

struct IncentiveSearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let onSearch: () async -> Void
    
    var body: some View {
        HStack {
            TextField("Search incentives", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isSearching)
            
            Button(action: {
                Task {
                    await onSearch()
                }
            }) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.blue)
            }
            .disabled(isSearching)
        }
        .padding()
    }
}

