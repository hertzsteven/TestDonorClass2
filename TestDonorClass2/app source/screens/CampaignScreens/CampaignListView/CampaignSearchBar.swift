import SwiftUI

struct CampaignSearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let onSearch: () async -> Void
    
    var body: some View {
        HStack {
            TextField("Search campaigns", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isSearching)
            
            Button {
                Task {
                    await onSearch()
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.blue)
            }
            .disabled(isSearching)
        }
        .padding(.horizontal)
    }
}

