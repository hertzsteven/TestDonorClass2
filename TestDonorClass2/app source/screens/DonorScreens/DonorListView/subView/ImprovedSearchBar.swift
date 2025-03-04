//
//  ImprovedSearchBar.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/28/25.
//


import SwiftUI

struct ImprovedSearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let placeholder: String
    let onSearch: () async -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Search bar with integrated button
            HStack(spacing: 0) {
                // Search field with magnifying glass icon
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                    
                    TextField(placeholder, text: $searchText)
                        .padding(.vertical, 10)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .disabled(isSearching)
                }
                .padding(.trailing, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10, corners: [.topLeft, .bottomLeft])
                
                // Search button connected directly to the field
                Button {
                    Task {
                        await onSearch()
                    }
                } label: {
                    Text("Search")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(height: 38)
                        .padding(.horizontal, 16)
                        .background(Color.blue)
                        .cornerRadius(10, corners: [.topRight, .bottomRight])
                }
                .disabled(isSearching)
            }
            .frame(height: 44)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal)
    }
}

// Extension to apply corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Implementation Example
// Replace your current SearchButton() function with this:
/*
func SearchComponent() -> some View {
    ImprovedSearchBar(
        searchText: $viewModel.searchText,
        isSearching: $isSearchingForDonor,
        placeholder: searchMode == .name ? "Search by name or company" : "Search by ID",
        onSearch: {
            Task {
                isSearchingForDonor = true
                try await viewModel.performSearch(mode: searchMode, newValue: viewModel.searchText)
                isSearchingForDonor = false
            }
        }
    )
}
*/

// MARK: - Preview
struct ImprovedSearchBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ImprovedSearchBar(
                searchText: .constant(""),
                isSearching: .constant(false),
                placeholder: "Search by name or company",
                onSearch: {
                    // Search action
                }
            )
            
            // Example with text
            ImprovedSearchBar(
                searchText: .constant("John Doe"),
                isSearching: .constant(false),
                placeholder: "Search by name or company",
                onSearch: {
                    // Search action
                }
            )
            
            // Example in searching state
            ImprovedSearchBar(
                searchText: .constant("Smith"),
                isSearching: .constant(true),
                placeholder: "Search by name or company",
                onSearch: {
                    // Search action
                }
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .previewLayout(.sizeThatFits)
    }
}