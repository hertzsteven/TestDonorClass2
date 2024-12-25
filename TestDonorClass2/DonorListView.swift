//
//  DonorListView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 12/24/24.
//


import SwiftUI

import SwiftUI

// MARK: - Main List View
struct DonorListView: View {
    @EnvironmentObject var donorObject: DonorObjectClass
    @StateObject private var viewModel: DonorListViewModel
    @State private var showingAddDonor = false
    
//    init(donorObject: DonorObjectClass) {
//        _viewModel = StateObject(wrappedValue: DonorListViewModel(donorObject: donorObject))
//    }
    init(donorObject: DonorObjectClass) {
        _viewModel = StateObject(wrappedValue: DonorListViewModel(donorObject: donorObject))
    }

    var body: some View {
        Group {
            switch donorObject.loadingState {
            case .notLoaded:
                LoadingView(message: "Initializing...")
                    .task {
                        await donorObject.loadDonors()
                    }
                
            case .loading:
                LoadingView(message: "Loading donors...")
                
            case .loaded:
                donorList
                
            case .error(let message):
                ErrorView(message: message) {
                    Task {
                        await donorObject.loadDonors()
                    }
                }
            }
        }
        .navigationTitle("Donors")
        .searchable(text: $viewModel.searchText)
        .onChange(of: viewModel.searchText) { _ in
            Task {
                await viewModel.performSearch()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddDonor = true }) {
                    Label("Add Donor", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddDonor) {
            DonorEditView(mode: .add)
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
                    NavigationLink(destination: DonorDetailView(donor: donor)) {
                        DonorRowView(donor: donor)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        if let index = indexSet.first {
                            try? await donorObject.deleteDonor(donorObject.donors[index])
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Row View
struct DonorRowView: View {
    let donor: Donor
    @State private var totalDonations: Double = 0
    @EnvironmentObject var donorObject: DonorObjectClass
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(donor.fullName)
                .font(.headline)
            if let email = donor.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text("Total Donations: $\(totalDonations, specifier: "%.2f")")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .task {
            do {
//                totalDonations = try await donorObject.getTotalDonations(for: donor)
            } catch {
                // Handle error if needed
            }
        }
    }
}

// MARK: - Detail View
struct DonorDetailView: View {
    let donor: Donor
    @State private var showingEditSheet = false
    @EnvironmentObject var donorObject: DonorObjectClass
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                if let salutation = donor.salutation {
                    LabeledContent("Salutation", value: salutation)
                }
                LabeledContent("First Name", value: donor.firstName)
                LabeledContent("Last Name", value: donor.lastName)
                if let jewishName = donor.jewishName {
                    LabeledContent("Jewish Name", value: jewishName)
                }
            }
            
            Section(header: Text("Contact Information")) {
                if let email = donor.email {
                    LabeledContent("Email", value: email)
                }
                if let phone = donor.phone {
                    LabeledContent("Phone", value: phone)
                }
            }
            
            Section(header: Text("Address")) {
                if let address = donor.address {
                    LabeledContent("Street", value: address)
                }
                if let city = donor.city {
                    LabeledContent("City", value: city)
                }
                if let state = donor.state {
                    LabeledContent("State", value: state)
                }
                if let zip = donor.zip {
                    LabeledContent("ZIP", value: zip)
                }
            }
        }
        .navigationTitle("Donor Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            DonorEditView(mode: .edit(donor))
        }
    }
}

// MARK: - Edit View
struct DonorEditView: View {
    enum Mode {
        case add
//        case isAdd
        case edit(Donor)
    }
    
    let mode: Mode
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var donorObject: DonorObjectClass
    
    @State private var salutation: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var jewishName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zip: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Salutation", text: $salutation)
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Jewish Name", text: $jewishName)
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Address")) {
                    TextField("Street Address", text: $address)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP", text: $zip)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Additional Information")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Edit Donor")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
            .onAppear {
                if case .edit(let donor) = mode {
                    // Populate fields with existing donor data
                    salutation = donor.salutation ?? ""
                    firstName = donor.firstName
                    lastName = donor.lastName
                    jewishName = donor.jewishName ?? ""
                    email = donor.email ?? ""
                    phone = donor.phone ?? ""
                    address = donor.address ?? ""
                    city = donor.city ?? ""
                    state = donor.state ?? ""
                    zip = donor.zip ?? ""
                    notes = donor.notes ?? ""
                }
            }
        }
    }
    
    private var isAdd: Bool {
        if case .add = mode {
            return true
        }
        return false
    }
    
    private func save() {
        let donor: Donor
        if case .edit(var existingDonor) = mode {
            // Update existing donor
            existingDonor.salutation = salutation.isEmpty ? nil : salutation
            existingDonor.firstName = firstName
            existingDonor.lastName = lastName
            existingDonor.jewishName = jewishName.isEmpty ? nil : jewishName
            existingDonor.email = email.isEmpty ? nil : email
            existingDonor.phone = phone.isEmpty ? nil : phone
            existingDonor.address = address.isEmpty ? nil : address
            existingDonor.city = city.isEmpty ? nil : city
            existingDonor.state = state.isEmpty ? nil : state
            existingDonor.zip = zip.isEmpty ? nil : zip
            existingDonor.notes = notes.isEmpty ? nil : notes
            donor = existingDonor
        } else {
            // Create new donor
            donor = Donor(
                salutation: salutation.isEmpty ? nil : salutation,
                firstName: firstName,
                lastName: lastName,
                jewishName: jewishName.isEmpty ? nil : jewishName,
                address: address.isEmpty ? nil : address,
                city: city.isEmpty ? nil : city,
                state: state.isEmpty ? nil : state,
                zip: zip.isEmpty ? nil : zip,
                email: email.isEmpty ? nil : email,
                phone: phone.isEmpty ? nil : phone,
                notes: notes.isEmpty ? nil : notes
            )
        }
        
        Task {
            do {
                if isAdd {
                    try await donorObject.addDonor(donor)
                } else {
                    try await donorObject.updateDonor(donor)
                }
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                // Handle error if needed
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
            
            Button("Retry") {
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
    NavigationView {
        DonorListView(donorObject: DonorObjectClass())
            .environmentObject(DonorObjectClass())
    }
}

struct DonorViews_Previews: PreviewProvider {
    // Sample data
    static let sampleDonor = Donor(
        id: 1,
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
    )
    
    // Sample donor object with different states
    static var loadedDonorObject: DonorObjectClass = {
        let object = DonorObjectClass()
        object.donors = [sampleDonor]
        object.loadingState = .loaded
        return object
    }()
    
    static var emptyDonorObject: DonorObjectClass = {
        let object = DonorObjectClass()
        object.donors = []
        object.loadingState = .loaded
        return object
    }()
    
    static var loadingDonorObject: DonorObjectClass = {
        let object = DonorObjectClass()
        object.loadingState = .loading
        return object
    }()
    
    static var errorDonorObject: DonorObjectClass = {
        let object = DonorObjectClass()
        object.loadingState = .error("Failed to load donors")
        return object
    }()
    
    static var previews: some View {
        Group {
            // Main List View - Different States
            NavigationView {
                DonorListView(donorObject: loadedDonorObject)
                    .environmentObject(loadedDonorObject)
            }
            .previewDisplayName("List View - Loaded")
            
            NavigationView {
                DonorListView(donorObject: emptyDonorObject)
                    .environmentObject(emptyDonorObject)
            }
            .previewDisplayName("List View - Empty")
            
            NavigationView {
                DonorListView(donorObject: loadingDonorObject)
                    .environmentObject(loadingDonorObject)
            }
            .previewDisplayName("List View - Loading")
            
            NavigationView {
                DonorListView(donorObject: errorDonorObject)
                    .environmentObject(errorDonorObject)
            }
            .previewDisplayName("List View - Error")
            
            // Detail View
            NavigationView {
                DonorDetailView(donor: sampleDonor)
                    .environmentObject(loadedDonorObject)
            }
            .previewDisplayName("Detail View")
            
            // Row View
            DonorRowView(donor: sampleDonor)
                .environmentObject(loadedDonorObject)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Row View")
            
            // Edit Views
            NavigationView {
                DonorEditView(mode: .add)
                    .environmentObject(loadedDonorObject)
            }
            .previewDisplayName("Add Donor View")
            
            NavigationView {
                DonorEditView(mode: .edit(sampleDonor))
                    .environmentObject(loadedDonorObject)
            }
            .previewDisplayName("Edit Donor View")
            
            // Support Views
            LoadingView(message: "Loading donors...")
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Loading View")
            
            ErrorView(message: "Failed to load donors") {}
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Error View")
            
            EmptyStateView(
                message: "No donors found",
                action: {},
                actionTitle: "Add Donor"
            )
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Empty State View")
        }
    }
}
