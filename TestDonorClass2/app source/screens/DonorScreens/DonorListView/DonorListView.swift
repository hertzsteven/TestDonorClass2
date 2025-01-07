    //
    //  DonorListView.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 12/24/24.
    //

    import SwiftUI

    // MARK: - Main List View
    struct DonorListView: View {
        @EnvironmentObject var donorObject: DonorObjectClass
        @EnvironmentObject var donationObject: DonationObjectClass
        @StateObject private var viewModel: DonorListViewModel
        @State private var showingAddDonor = false
        @State private var showingDefaults = false
        @State var searchMode: SearchMode = .name
        
        enum SearchMode: String, CaseIterable {
            case name = "Name"
            case id = "ID"
        }
        
        init(donorObject: DonorObjectClass, maintenanceMode: Bool) {
            _viewModel = StateObject(wrappedValue: DonorListViewModel(donorObject: donorObject, maintenanceMode: maintenanceMode))
        }

        var body: some View {
            VStack {
//                if !donorObject.donors.isEmpty {
//                    Text("Select a Donor")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .padding([.leading,.top])
//                }
                Group {
                    switch donorObject.loadingState {
                        
                    case .notLoaded:
                        let _ = print("Not loaded yet")
                        LoadingView(message: "Initializing...")
                        
                    case .loading:
                        let _ = print("loading")
                        LoadingView(message: "Loading donors...")
                        
                    case .loaded:
                        let _ = print("loaded")
                        donorList
                        
                    case .error(let message):
                        let _ = print("in error")
                        ErrorView(message: message) {
                            Task {
                                print("Retrying...")
                                await donorObject.loadDonors()
                                print("Retry complete")
                            }
                        }
                    }
                }
                .navigationTitle(viewModel.maintenanceMode ? "Update Donor" : "Enter Donation")
                
                .searchable(text: $viewModel.searchText, prompt: searchMode == .name ? "Search by name" : "Search by ID")
                .safeAreaInset(edge: .top) {
                    if donorObject.loadingState == .loaded {
                        Picker("Search Mode", selection: $searchMode) {
                            ForEach(SearchMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }
                }
                
                .onChange(of: viewModel.searchText, initial: false) { oldValue, newValue in
                    Task {
                        try await viewModel.performSearch(mode: searchMode, oldValue: oldValue, newValue: newValue)
                    }
                }
                .onChange(of: searchMode) { oldValue, newValue in
                    viewModel.searchText = "" // Clear search when changing modes
                }
                
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: { showingAddDonor = true }) {
                            Label("Add Donor", systemImage: "plus")
                        }
                        
                        if !viewModel.maintenanceMode {
                            Button(action: { showingDefaults = true }) {
                                Label("Defaults", systemImage: "gear")
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingAddDonor) {
                    DonorEditView(mode: .add)
                }
                .sheet(isPresented: $showingDefaults) {
                    DefaultDonationSettingsView()
                }
            }
        }
        
        private var donorList: some View {

                List {
                    if donorObject.donors.isEmpty {
                        EmptyStateView(
                            message: "No donors found",
                            action: { Task { await donorObject.loadDonors() }},
                            actionTitle: "Refresh"
                        )
                    } else {
                        ForEach(donorObject.donors) { donor in
                            if viewModel.maintenanceMode {
                                NavigationLink(destination: DonorDetailView(donor: donor)) {
                                    DonorRowView(donor: donor, maintenanceMode: viewModel.maintenanceMode)
                                }
                            } else {
                                
                                NavigationLink(destination: DonationEditView(donor: donor)
                                    .environmentObject(donationObject)) {
                                        DonorRowView(donor: donor, maintenanceMode: viewModel.maintenanceMode)
                                    }
                                
                            }
                        }
                        .onDelete(perform: viewModel.maintenanceMode ? { indexSet in
                            Task {
                                if let index = indexSet.first {
                                    try? await donorObject.deleteDonor(donorObject.donors[index])
                                }
                            }
                        } : nil)
                    }
                }
        }
    }





    // MARK: - Support Views
    struct LoadingView: View {
        let message: String
        
        var body: some View {
            VStack {
                ProgressView()
                    .padding()
                Text(message)
                    .foregroundColor(.secondary)
            }
        }
    }

    struct ErrorView: View {
        let message: String
        let retryAction: () -> Void
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text("Error")
                    .font(.title)
                
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("Retry It") {
                    retryAction()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    struct EmptyStateView: View {
        let message: String
        let action: (() -> Void)?
        let actionTitle: String?
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if let action = action, let actionTitle = actionTitle {
                    Button(actionTitle) {
                        action()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    //
    //  DonorViews.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 12/24/24.
    //

    import SwiftUI

    #Preview {
        // Create a donor object with mock data
        let donorObject: DonorObjectClass = {
            let object = DonorObjectClass()
            object.donors = [
                Donor(
                    firstName: "John",
                    lastName: "Doe",
                    jewishName: "Yaakov",
                    address: "123 Main St",
                    city: "New York",
                    state: "NY",
                    zip: "10001",
                    email: "john@example.com",
                    phone: "555-555-5555",
                    notes: "Important donor"
                ),
                Donor(
                    firstName: "Sarah",
                    lastName: "Cohen",
                    jewishName: "Sara",
                    address: "456 Broadway",
                    city: "Brooklyn",
                    state: "NY",
                    zip: "11213",
                    email: "sarah@example.com",
                    phone: "555-555-5556",
                    notes: "Regular contributor"
                )
            ]
            object.loadingState = .loaded
            return object
        }()
        
        // Create donation object
        let donationObject = DonationObjectClass()
        
        return NavigationView {
            DonorListView(donorObject: donorObject, maintenanceMode: false)
                .environmentObject(donorObject)
                .environmentObject(donationObject)
        }
    }
