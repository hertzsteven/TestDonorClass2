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
    
        // Alert handling properties
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var selectedDonor: Donor? = nil
    
    @State private var donorCount: Int = 0
    
    
    enum SearchMode: String, CaseIterable {
        case name = "Name"
        case id = "ID"
    }
    
    init(donorObject: DonorObjectClass, maintenanceMode: Bool) {
        _viewModel = StateObject(wrappedValue: DonorListViewModel(donorObject: donorObject, maintenanceMode: maintenanceMode))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            /*
            Group {
                switch donorObject.loadingState {
                    
                case .notLoaded:
                    let _ = print("Not loaded yet")
                    LoadingView(message: "Initializing...")
                    
                case .loading:
                    let _ = print("loading")
                    LoadingView(message: "Loading donors...")
                    
                case .loaded:
                    let _ = print("donors loaded")
                    if viewModel.maintenanceMode {
                        donorList
                    } else {
                        //                    donorList
//                    if donorCount == 0 {
//                        VStack {
//                            Button(action: {
//                                showingAddDonor = true }) {
//                                    Label("Add Donor", systemImage: "plus") }
//                            EmptyStateView(
//                                message: "No donors found",
//                                action: { Task { await donorObject.loadDonors() }},
//                                actionTitle: "Refresh"
//                            )
//                        }
//                    } else {
                        newDonorList}
//                }
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
            */
            if viewModel.maintenanceMode {
                VStack {
                        // Buttons for Search and Clear
                        HStack {
                            Button(action: {print("search")}) {
                                Text("Search")
                                    .frame(maxWidth: .infinity, minHeight: 36)
                                    .padding(.horizontal, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {print("search")}) {
                                Text("Clear")
                                    .frame(maxWidth: .infinity, minHeight: 36)
                                    .padding(.horizontal, 12)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding([.horizontal, .top])
                    donorList
                }
               
            } else {
                    //                    donorList
                    //                    if donorCount == 0 {
                    //                        VStack {
                    //                            Button(action: {
                    //                                showingAddDonor = true }) {
                    //                                    Label("Add Donor", systemImage: "plus") }
                    //                            EmptyStateView(
                    //                                message: "No donors found",
                    //                                action: { Task { await donorObject.loadDonors() }},
                    //                                actionTitle: "Refresh"
                    //                            )
                    //                        }
                    //                    } else {
                
                newDonorList
            }

        }
        .onAppear {

            Task {
                donorCount = try await donorObject.getCount()
                donorObject.loadingState = .loaded
            }

        }
        .navigationTitle(viewModel.maintenanceMode ? "Update Donor" : "Enter Donation")
        .searchable(text: $viewModel.searchText, prompt: searchMode == .name ? "Search by name" : "Search by ID")
        .onChange(of: viewModel.searchText) { oldValue, newValue in
            Task {
                if oldValue.count > 0 && newValue.count == 0 {
                    try await viewModel.performSearch(mode: searchMode, newValue: newValue)
                }
                
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

        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        
        .sheet(isPresented: $showingAddDonor) {
            DonorEditView(mode: .add)
        }
        .sheet(isPresented: $showingDefaults) {
            DefaultDonationSettingsView()
//                .environmentObject(defaultDonationSettingsViewModel)
        }
    }
    
    private var donorList: some View {
        VStack(alignment: .leading, spacing: 0) {
                // Add Select a Donor text as part of the list
            if !donorObject.donors.isEmpty {
                Text("Select a Donor")
                    .font(.title)
                    .fontWeight(.regular)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            
            List {
                if donorObject.donors.isEmpty {
                    EmptyStateView(
                        message: "No donors found",
                        action: { print("refres")},
                        actionTitle: "Refresh"
                    )
                } else {
                    ForEach(donorObject.donors) { donor in
                        if viewModel.maintenanceMode {
                            NavigationLink(destination: DonorDetailView(donor: donor)) {
                                DonorRowView(donor: donor, maintenanceMode: viewModel.maintenanceMode)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        } else {
                            
                            NavigationLink(destination: DonationEditView(donor: donor)
                                .environmentObject(donationObject)) {
                                    DonorRowView(donor: donor, maintenanceMode: viewModel.maintenanceMode)
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .onDelete(perform:  viewModel.maintenanceMode ? handleDelete : nil)
                }
            }
        }
    }
    
    var newDonorList: some View {
        
            NavigationSplitView {
                VStack {
                        // Buttons for Search and Clear
                        HStack {
                            Button(action: {
                                Task {
                                    try await viewModel.performSearch(mode: searchMode, newValue: viewModel.searchText)
                                }
                            }) {
                                Text("Search")
                                    .frame(maxWidth: .infinity, minHeight: 36)
                                    .padding(.horizontal, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding([.horizontal])
                    switch donorObject.donors.isEmpty {
                    case true:
                        Text("Please search for a donor").tint(.gray)
                        Spacer()
                    case false:
                        List(selection: $selectedDonor) {
                            ForEach(donorObject.donors) { donor in
                                NavigationLink(value: donor) {
                                    DonorRowView(donor: donor, maintenanceMode: viewModel.maintenanceMode)
                                }
                            }
                            .onDelete(perform: viewModel.maintenanceMode ? handleDelete : nil)
                        }
                    }
                }

                .toolbar {
                    if let donor = selectedDonor {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                print("clear")
                                selectedDonor = nil
                            }) {
                                Text("Clear").foregroundColor(Color.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }else {
                        ToolbarItemGroup {
                            Button("Add Donor", action: { showingAddDonor = true })
                            if !viewModel.maintenanceMode {
                                Button(action: { showingDefaults = true }) {
                                    Label("Defaults", systemImage: "gear")
                                }
                            }
                        }
                    }
                    ToolbarItem(placement: .bottomBar) {
                        if donorObject.loadingState == .loaded {
                            Picker("Search Mode", selection: $searchMode) {
                                ForEach(SearchMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                }
        } detail: {
            if viewModel.maintenanceMode {

                if let donor = selectedDonor {
                    
                    DonorDetailView(donor: donor)
                        .environmentObject(donationObject)
                        .toolbar(.hidden, for: .tabBar)
                } else {
                    Text("Select a donor")
                }

            } else {
                
                if let donor = selectedDonor {
                    DonationEditView(donor: donor)
                        .environmentObject(donationObject)
                        .toolbar(.hidden, for: .tabBar)
                } else {
                    Text("Select a donor")
                        .toolbar(.visible, for: .tabBar)
                }
            }

        }
    }
    
    private func handleDelete(at indexSet: IndexSet) {
        Task {
            if let index = indexSet.first {
                do {
                    try await donorObject.deleteDonor(donorObject.donors[index])
                } catch {
                    await MainActor.run {
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                }
                
            }
        }
    }
}


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
