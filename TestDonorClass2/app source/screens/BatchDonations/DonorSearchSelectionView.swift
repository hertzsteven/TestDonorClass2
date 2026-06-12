//
//  DonorSearchSelectionView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 3/1/25.
//

import SwiftUI

struct DonorSearchSelectionView: View {
    
    enum SearchMode: String, CaseIterable {
        case name = "Name"
        case address = "Address"
    }
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var donorObject: DonorObjectClass
    
    @State private var searchMode: SearchMode = .name
    @State private var searchText = ""
    @State private var secondarySearchText = ""
    @State private var searchResults: [Donor] = []
    @State private var filteredResults: [Donor] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    @FocusState private var isSearchFieldFocused: Bool
    @FocusState private var isSecondarySearchFocused: Bool
    
    @State private var showingAddDonor = false
    @State private var newDonor = Donor()
    
    private var searchPlaceholder: String {
        switch searchMode {
        case .name: return "Search by name or company"
        case .address: return "Search by address, city, state, or zip"
        }
    }
    
    var onDonorSelected: (Donor) -> Void
    let initialSearchText: String?
    
    init(onDonorSelected: @escaping (Donor) -> Void, initialSearchText: String? = nil) {
        self.onDonorSelected = onDonorSelected
        self.initialSearchText = initialSearchText
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                primarySearchBar
                searchModePicker

                if !searchResults.isEmpty {
                    secondaryFilterBar
                }

                if searchResults.isEmpty {
                    searchActionButton
                }

                contentArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Find Donor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        prepareNewDonor()
                        showingAddDonor = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Add Donor")
                        }
                        .font(.subheadline)
                    }
                }
            }
            .onChange(of: secondarySearchText) { _, newValue in
                filterResults(query: newValue)
            }
            .onChange(of: searchResults) { _, newResults in
                if newResults.isEmpty && !isSearching {
                    isSearchFieldFocused = true
                    isSecondarySearchFocused = false
                } else if !newResults.isEmpty {
                    isSearchFieldFocused = false
                    isSecondarySearchFocused = true
                }
            }
            .task {
                isSearchFieldFocused = true
                
                // Pre-populate search field if initial search text is provided
                if let initialText = initialSearchText, !initialText.isEmpty {
                    searchText = initialText
                    // Automatically perform search if initial text is provided
                    await performSearch()
                }
            }
        }
        .sheet(isPresented: $showingAddDonor, onDismiss: {
            print("Add New Donor sheet dismissed. Current donor data:")
            print("Name: \(newDonor.firstName ?? "") \(newDonor.lastName ?? "")")
            print("Email: \(newDonor.email ?? "Not provided")")
            print("Company: \(newDonor.company ?? "Not provided")")
        }) {
            BatchDonorEditView(
                donor: $newDonor,
                onSave: { savedDonor in
                    onDonorSelected(savedDonor)
                    dismiss()
                },
                onCancel: { showingAddDonor = false }
            )
            .environmentObject(donorObject)
            .interactiveDismissDisabled()
        }
    }

    private var primarySearchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .padding(.leading, 8)

            TextField(searchPlaceholder, text: $searchText)
                .padding(.vertical, 10)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .disabled(isSearching)
                .focused($isSearchFieldFocused)
                .onSubmit {
                    if !searchText.isEmpty && !isSearching && searchResults.isEmpty {
                        Task {
                            await performSearch()
                        }
                    }
                }

            if !searchText.isEmpty {
                Button("Clear search", systemImage: "xmark.circle.fill") {
                    searchText = ""
                    searchResults = []
                    filteredResults = []
                    isSearchFieldFocused = true
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.gray)
                .padding(.trailing, 8)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var searchModePicker: some View {
        Picker("Search Mode", selection: $searchMode) {
            ForEach(SearchMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: searchMode) { _, _ in
            searchText = ""
            searchResults = []
            filteredResults = []
            secondarySearchText = ""
            errorMessage = nil
            isSearchFieldFocused = true
        }
    }

    private var secondaryFilterBar: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "text.magnifyingglass")
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)

                TextField("Filter results by address", text: $secondarySearchText)
                    .padding(.vertical, 8)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .focused($isSecondarySearchFocused)

                if !secondarySearchText.isEmpty {
                    Button("Clear filter", systemImage: "xmark.circle.fill") {
                        secondarySearchText = ""
                        isSecondarySearchFocused = true
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.gray)
                    .padding(.trailing, 8)
                }
            }
            .padding(6)
            .background(Color(.systemGray6).opacity(0.7))
            .clipShape(.rect(cornerRadius: 8))
            .padding(.horizontal)

            if !secondarySearchText.isEmpty {
                Text("Showing \(filteredResults.count) of \(searchResults.count) results")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var searchActionButton: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await performSearch()
                }
            } label: {
                HStack {
                    Text("Search")
                    if isSearching {
                        ProgressView()
                            .padding(.leading, 5)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 10))
            }
            .disabled(searchText.isEmpty || isSearching)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var contentArea: some View {
        switch (isSearching, errorMessage, searchResults.isEmpty, searchText.isEmpty) {
        case (true, _, _, _):
            ScrollView {
                ProgressView("Searching...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

        case (_, .some(let error), _, _):
            ScrollView {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                        .padding()

                    Text(error)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

        case (false, nil, true, false):
            ScrollView {
                VStack {
                    Image(systemName: "person.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                        .padding()

                    Text("No donors found matching '\(searchText)'")
                        .padding()

                    Text("Try a different search or add a new donor")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

        case (false, nil, true, true):
            ScrollView {
                VStack {
                    Image(systemName: "person.text.rectangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                        .padding()

                    Text(
                        searchMode == .name
                            ? "Enter a name or company to search for donors"
                            : "Enter an address, city, state, or zip to search"
                    )
                    .multilineTextAlignment(.center)
                    .padding()

                    Text("or create a new donor")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

        case (false, nil, false, _):
            VStack(alignment: .leading, spacing: 0) {
                Text(
                    "Showing \(secondarySearchText.isEmpty ? searchResults.count : filteredResults.count) of \(searchResults.count) results"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 4)

                List {
                    ForEach(secondarySearchText.isEmpty ? searchResults : filteredResults) { donor in
                        Button {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                onDonorSelected(donor)
                                dismiss()
                            }
                        } label: {
                            DonorSearchResultRow(donor: donor, formattedName: formatName(donor))
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.visible)
                    }
                }
                .listStyle(.plain)
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }
    
    private func prepareNewDonor() {
        newDonor = Donor()
    }
    
    private func filterResults(query: String) {
        if query.isEmpty {
            filteredResults = searchResults
        } else {
            filteredResults = searchResults.filter { donor in
                let addressMatch = donor.address?.localizedCaseInsensitiveContains(query) ?? false
                let cityMatch = donor.city?.localizedCaseInsensitiveContains(query) ?? false
                let stateMatch = donor.state?.localizedCaseInsensitiveContains(query) ?? false
                return addressMatch || cityMatch || stateMatch
            }
        }
    }
    
    private func formatName(_ donor: Donor) -> String {
        var parts: [String] = []
        if let salutation = donor.salutation { parts.append(salutation) }
        if let first = donor.firstName { parts.append(first) }
        if let last = donor.lastName { parts.append(last) }
        return parts.joined(separator: " ")
    }
    
    private func performSearch() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil

        // DEBUG: Test if the repository is working
        print("DEBUG: Testing repository connection...")
        do {
            let testCount = try await donorObject.getCount()
            print("DEBUG: Repository working - donor count: \(testCount)")
        } catch {
            print("DEBUG: Repository failing - error: \(error)")
            await MainActor.run {
                self.errorMessage = "Repository connection failed: \(error.localizedDescription)"
                self.isSearching = false
            }
            return
        }

        do {
            let results: [Donor]
            switch searchMode {
            case .name:
                results = try await donorObject.searchDonorsWithReturn(searchText)
            case .address:
                results = try await donorObject.searchDonorsByAddressWithReturn(searchText)
            }
            await MainActor.run {
                self.searchResults = results
                self.filteredResults = results
                self.isSearching = false
                self.secondarySearchText = ""
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error searching: \(error.localizedDescription)"
                self.searchResults = []
                self.filteredResults = []
                self.isSearching = false
            }
        }
    }
}

private struct DonorSearchResultRow: View {
    let donor: Donor
    let formattedName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(formattedName.capitalized)
                    .font(.subheadline)
                    .bold()
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if let city = donor.city, let state = donor.state {
                        Text("\(city), \(state)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let zip = donor.zip, !zip.isEmpty {
                        Text(zip)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let address = donor.address, !address.isEmpty {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(.rect)
    }
}