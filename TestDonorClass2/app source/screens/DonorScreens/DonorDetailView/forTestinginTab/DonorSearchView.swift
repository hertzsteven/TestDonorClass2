//
//  DonorSearchView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/18/25.
//


import SwiftUI
    // MARK: - Views
    struct DonorSearchView: View {
        //    @StateObject private var viewModel = DonorSearchViewModel(donorObject: DonorObjectClass())
        
        @State private var scannedCode: String = ""
        @State private var isShowingScanner: Bool = false
        
        enum SearchMode: String, CaseIterable {
            case id = "ID"
            case name = "Name"
        }
        // Add this state property
        @State private var searchMode: SearchMode = .name
        
        @StateObject private var viewModel: DonorSearchViewModel
        
        @State private var isShowingSheet = false
        
        init(donorObject: DonorObjectClass) {
            _viewModel = StateObject(wrappedValue: DonorSearchViewModel(donorObject: donorObject))
        }
        
        
        var body: some View {
            //        NavigationView {
            VStack {
                searchBar
                if viewModel.hasSearched {
                    if viewModel.donors.isEmpty {
                        noResultsView
                    } else {
                        donorList2
                    }
                } else {
                    initialStateView
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                
                ToolbarItem(placement: .principal) {
                    Picker("Search Mode", selection: $searchMode) {
                        ForEach(SearchMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .frame(width:250)
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .onChange(of: searchMode) { oldValue, newValue in
                        viewModel.clearDonors()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if searchMode == .id {
                        Button(action: {
                            isShowingScanner  = true
                        }) {
                            Image(systemName: "barcode.viewfinder")
                        }
                    }
                }
            }
            
            .sheet(isPresented: $isShowingScanner) {
                BarcodeScannerView(scannedCode: $scannedCode)
            }
            
            .onChange(of: scannedCode) { newValue in
                if !newValue.isEmpty {
                        //                isShowingResultSheet = true
                    print("Scanned code: \(newValue)")
                    $viewModel.searchText.wrappedValue = newValue
                    Task {
                        try await viewModel.performSearch(mode: searchMode, newValue: viewModel.searchText)
                    }
                        //                Task { await handleScannedCode(code: newValue) }
                }
            }
            
            //            .navigationTitle("Donors")
            //        }
        }
        
        
        private var searchBar: some View {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search donors...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .submitLabel(.search)
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    Task {
                        do {
                            try await viewModel.performSearch(mode: searchMode, newValue: viewModel.searchText)
                        }
                        catch {
                            print("Error searching: \(error)")
                        }
                    }
                    //                viewModel.searchForDonors()
                }) {
                    Text("Search")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        
        private var initialStateView: some View {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("Enter search terms and press Search")
                    .foregroundColor(.gray)
            }
            .frame(maxHeight: .infinity)
        }
        
        private var noResultsView: some View {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("No donors found")
                    .foregroundColor(.gray)
            }
            .frame(maxHeight: .infinity)
        }
        
        private var donorList2: some View {
            List(viewModel.donors, id: \.uuid) { donor in
                NavigationLink(destination: DonationEditView(donor: donor)) {
                    DonorRowView2(donor: donor)
                }
            }
        }
    }



    struct DonorDetailView2: View {
        let donor: Donor
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Contact Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contact Information")
                            .font(.headline)
                        
                        if let email = donor.email {
                            HStack {
                                Image(systemName: "envelope")
                                Text(email)
                            }
                        }
                        
                        if let phone = donor.phone {
                            HStack {
                                Image(systemName: "phone")
                                Text(phone)
                            }
                        }
                    }
                    
                    // Address
                    if let address = donor.address {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Address")
                                .font(.headline)
                            
                            Text(address)
                            if let city = donor.city, let state = donor.state, let zip = donor.zip {
                                Text("\(city), \(state) \(zip)")
                            }
                        }
                    }
                    
                    // Notes
                    if let notes = donor.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            Text(notes)
                        }
                    }
                    
                    // Dates
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Record Information")
                            .font(.headline)
                        Text("Created: \(formatDate(donor.createdAt))")
                        Text("Updated: \(formatDate(donor.updatedAt))")
                    }
                }
                .padding()
            }
            .navigationTitle(formatName(donor))
        }
        
        private func formatName(_ donor: Donor) -> String {
            var components: [String] = []
            if let salutation = donor.salutation { components.append(salutation) }
            if let firstName = donor.firstName { components.append(firstName) }
            if let lastName = donor.lastName { components.append(lastName) }
            return components.joined(separator: " ")
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }


    struct DonorSearchView_Previews: PreviewProvider {
        static var previews: some View {
            // Create a dummy DonorObjectClass instance.
            // Adjust the initializer if DonorObjectClass requires parameters.
            let dummyDonorObject = DonorObjectClass()
            
            // Wrap in a NavigationView if you want to preview NavigationLinks.
            NavigationStack {
                DonorSearchView(donorObject: dummyDonorObject)
            }
            // Optionally, set a preview device or color scheme:
            .previewDevice("iPhone 13")
            .preferredColorScheme(.light) // Change to .dark to preview dark mode.
        }
    }
