//
//  DonorListView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 12/24/24.
//

import SwiftUI

// MARK: - Main List View
struct DonorListView: View {
    
    @EnvironmentObject var donorObject        : DonorObjectClass
    @EnvironmentObject var donationObject     : DonationObjectClass
    
    @StateObject private var viewModel        : DonorListViewModel
    
    @State private var scannedCode          = ""
    @State private var isShowingScanner     = false
    @State private var isShowingResultSheet = false
    
    
    @State private var showingAddDonor = false
    @State private var showingDefaults = false
    @State var searchMode: SearchMode  = .name
    @State var clearTheDonors: Bool    = false
    @State var isSearchingForDonor: Bool = false
    
    // Alert handling properties
    @State private var showAlert       = false
    @State private var alertMessage    = ""
    
    @State  var selectedDonor: Donor?  = nil
    @State private var selectedDonorID: Donor.ID?  // Which donor is currently selected?
    
    /// A new donor used for the "Add Donor" flow (since we need a binding).
    @State private var blankDonor       = Donor()
    
    @State private var donorCount: Int = 0
    
    enum SearchMode: String, CaseIterable {
        case name = "Name"
        case id = "ID"
    }
    
    init(donorObject: DonorObjectClass, maintenanceMode: Bool) {
        _viewModel = StateObject(wrappedValue: DonorListViewModel(donorObject: donorObject,
                                                                  maintenanceMode: maintenanceMode))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            newDonorList
        }
        
        .onAppear {
            Task {
                await doOnAppearProcess()
            }
        }
        .navigationTitle(viewModel.maintenanceMode ? "Update Donor" : "Enter Donation")
        .searchable(text: $viewModel.searchText, prompt: searchMode == .name ? "Search by name or company" : "Search by ID")
        
        .sheet(isPresented: $isShowingScanner) {
            BarcodeScannerView(scannedCode: $scannedCode)
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
        .sheet(isPresented: $isShowingResultSheet) {
            VStack {
                Text("Scanned Code: \(scannedCode)")
                    .padding()
                Button("Dismiss") {
                    isShowingResultSheet = false
                }
                .padding()
            }
        }
        
        
        .onChange(of: viewModel.searchText) { oldValue, newValue in
            Task { await handleSearchTextChange(from: oldValue, to: newValue) }
        }
        .onChange(of: searchMode) { viewModel.searchText = "" }
        
        .toolbar { toolBarListDonors() }
        //            ToolbarItemGroup(placement: .navigationBarTrailing) {
        //                Button(action: { showingAddDonor = true }) {
        //                    Label("Add Donor", systemImage: "plus")
        //                }
        //
        //                if !viewModel.maintenanceMode {
        //                    Button(action: { showingDefaults = true }) {
        //                        Label("Defaults", systemImage: "gear")
        //                    }
        //                }
        //            }
        
        
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        
        .sheet(isPresented: $showingAddDonor) {
            DonorEditView(mode: .add, donor: $blankDonor)
        }
        .sheet(isPresented: $showingDefaults) {
            DefaultDonationSettingsView()
            //                .environmentObject(defaultDonationSettingsViewModel)
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

extension DonorListView {
    private func handleSearchTextChange(from oldValue: String, to newValue: String) async {
        let isClearing = !oldValue.isEmptyOrWhitespace  && newValue.isEmptyOrWhitespace
        
        if isClearing {
            clearTheDonors = true
            do {
                try await viewModel.performSearch(mode: searchMode, newValue: newValue)
            } catch {
                // Handle specific errors
                print("Search failed: \(error)")
                // You might want to:
                // - Update UI to show error state
                // - Log the error
                // - Show an alert to the user
                // await handleSearchError(error)
            }
            clearTheDonors = false
        }
    }
}

extension DonorListView {
    
    fileprivate func SearchModeSegmented() -> some View {
        return Picker("Search Mode", selection: $searchMode) {
            ForEach(SearchMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
 
    fileprivate func SearchComponent() -> some View {
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
    
    fileprivate func SearchButton() -> some View {
        return // Buttons for Search and Clear
        HStack {
            Button(action: {
                Task {
                    isSearchingForDonor.toggle()
                    try await viewModel.performSearch(mode: searchMode, newValue: viewModel.searchText)
                    isSearchingForDonor.toggle()
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
    }
    
    fileprivate func groupBoxInstructions() -> some View {
        return GroupBox("For Selected Donor") {
            VStack(alignment: .leading, spacing:8) {
                HStack {
                    Label {
                        Text("Enter Donation").font(.callout)
                    } icon: {
                        Image(systemName: "dollarsign.circle").foregroundStyle(.blue)
                            .font(.system(size: 20, weight: .none, design: .default))
                    }
                }
                .padding(.top, 4)
                
                HStack {
                    Label {
                        Text("See Information").font(.callout)
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                            .font(.system(size: 18, weight: .none, design: .default))
                    }
                    Spacer()
                }
                
                Text("Setup")
                    .font(.system(size: 18, weight: .medium, design: .default))
                    .padding(.top, 8)
                HStack {
                    Label {
                        Text("Default Donation").font(.callout)
                    } icon: {
                        Image(systemName: "gear")
                            .foregroundStyle(.blue)
                            .font(.system(size: 20, weight: .none, design: .default))
                    }
                }
                HStack {
                    Label {
                        Text("Add Donor").font(.callout)
                    } icon: {
                        Image(systemName: "plus")
                            .foregroundStyle(.blue)
                            .font(.system(size: 20, weight: .none, design: .default))
                    }
                }
            }
        }
    }

    var newDonorList: some View {
        
        NavigationSplitView {
            VStack {
                SearchButton()
                
                SearchComponent()
                
                SearchModeSegmented()
                
                switch donorObject.donors.isEmpty || clearTheDonors {
                case true:
                    if isSearchingForDonor {
                        ProgressView()
                    } else {
                        EnhancedEmptyStateView()
                        Spacer()
                    }
//                case true:
//                    if isSearchingForDonor {
//                        ProgressView()
//                    } else {
//                        VStack {
//                            Text("Please search for a donor").tint(.gray)
////                            groupBoxInstructions()
////                                .padding()
////                                .background(Color(.systemBackground))
//                        }
//                    }
//                    Spacer()
                case false:
                    GroupBox(label: Label("Managing Donors", systemImage: "gear")) {
                            //                        Text("Managing Donation Incentives")
                            //                            .font(.headline)
                        VStack(alignment: .leading) {
                            Text("• Tap any donor to edit details")
                            Text("• Swipe left on a donor to delete")
                        }
                    }
                    .backgroundStyle(.thinMaterial)
                    .padding()
                    
                    List(selection: $selectedDonorID) {
                        
                        ForEach($donorObject.donors) { $donor in
//                            NavigationLink {
//
//                            } label: {
//                                DonorRowView(donor: donor, maintenanceMode: viewModel.maintenanceMode)
//                            }

                            NavigationLink(value: donor) {
                                DonorRowView(donor: donor, maintenanceMode: viewModel.maintenanceMode)
                            }
                        }
                        .onDelete(perform: viewModel.maintenanceMode ? handleDelete : nil)
                    }
                }
            }
            .toolbar { toolBarTrailLeftPane() }
//            .navigationTitle("Donor Hub")
        } detail: {
            DonorDetailContainer(
                donorID: selectedDonorID,
                isMaintenanceMode: viewModel.maintenanceMode
            )
        }
    }
}

// MARK: - Life Cycle Methods
extension DonorListView {
    
    fileprivate func doOnDisappearProcess() {
    }
    
    fileprivate func doOnAppearProcess() async {
        await loadTheData()
    }
    
    func loadTheData() async {
        do {
            donorCount = try await donorObject.getCount()
            donorObject.loadingState = .loaded
        } catch {
            print("Error: \(error)")
        }
    }
}

// MARK: - Toolbars
extension DonorListView {
    //    private var toolbarContent: some ToolbarContent {
    //        ToolbarItem(placement: .navigationBarLeading) {
    //            Button("Cancel") {
    //                presentationMode.wrappedValue.dismiss()
    //            }
    //        }
    //
    //        ToolbarItem(placement: .navigationBarTrailing) {
    //            Button("Save") {
    //                print("llll")
    //            }
    //            .disabled(true)
    //        }
    //    }
    
    
    @ToolbarContentBuilder
    func toolBarTrailLeftPane() -> some ToolbarContent {
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
            ToolbarItem(placement: .topBarLeading) {
                Text(viewModel.maintenanceMode ? "Information" : "Donations")
                    .foregroundColor(.gray)
                    .font(.caption)
                    .animation(.easeInOut, value: viewModel.maintenanceMode)
            }
            ToolbarItemGroup {
                if viewModel.maintenanceMode {
                    Button { showingAddDonor = true } label: {
                        Text(Image(systemName: "plus"))
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Button(action: { showingDefaults = true }) {
                        Label("Defaults", systemImage: "gear")
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                if searchMode == .id {
                    Button(action: {
                        isShowingScanner.toggle()
                        print("Scan \(searchMode)")
                    }) {
                        Label("Scan Barcode", systemImage: "barcode")
                    }
                }
                
                Button {
                    viewModel.maintenanceMode.toggle()
                }  label: {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.maintenanceMode ? "info.circle.fill" : "info.circle")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                        
                        Image(systemName: !viewModel.maintenanceMode ? "dollarsign.circle.fill" : "dollarsign.circle")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                }

//                Button {
//                    viewModel.maintenanceMode.toggle()
//                }  label: {
//                    HStack(spacing: 8) {
//                        Image(systemName: "info.circle")
//                            .foregroundColor(.blue)
//                            .background(
//                                Circle()
//                                    .stroke(viewModel.maintenanceMode ? Color.blue : Color.clear, lineWidth: 2)
//                                    .padding(-4)
//                            )
//
//                        Image(systemName: "dollarsign.circle")
//                            .foregroundColor(.blue)
//                            .background(
//                                Circle()
//                                    .stroke(!viewModel.maintenanceMode ? Color.blue : Color.clear, lineWidth: 2)
//                                    .padding(-4)
//                            )
//                    }
//                }

                
//                Button {
//                    viewModel.maintenanceMode.toggle()
//                }  label: {
//                    Text(viewModel.maintenanceMode ? Image(systemName: "info.circle") : Image(systemName: "dollarsign.circle"))
//                }
                
            }
        }
//        ToolbarItem(placement: .bottomBar) {
//            if donorObject.loadingState == .loaded {
//                Picker("Search Mode", selection: $searchMode) {
//                    ForEach(SearchMode.allCases, id: \.self) { mode in
//                        Text(mode.rawValue).tag(mode)
//                    }
//                }
//                .pickerStyle(.segmented)
//                .padding(.horizontal)
//                .padding(.vertical, 8)
//            }
//        }
    }
        //
    @ToolbarContentBuilder
    func toolBarListDonors() -> some ToolbarContent {
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
