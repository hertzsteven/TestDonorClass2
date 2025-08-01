//
    //  DonorDetailView.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 1/1/25.
    //

    import SwiftUI
    // MARK: - Detail View
struct DonorDetailView: View {
    @Binding var donor: Donor
    
    @State private var showingEditSheet = false
    @EnvironmentObject var donorObject: DonorObjectClass
    @EnvironmentObject var donationObject: DonationObjectClass
    @Environment(\.presentationMode) var presentationMode
    
        // Add state for donations and loading state
        @State private var donorDonations: [Donation] = []
        @State private var isLoadingDonations = true // Changed to true by default
        @State private var donationsError: String? = nil

        /// A new donor used for the "Add Donor" flow (since we need a binding).
        @State private var blankDonor = Donor()
    
    // Add state for testing sheet
    @State private var showingTestSheet = false
    @State private var showingTextView = false
    @State private var showingStringView = false
    @State private var showingDonationDetail = false
    @State private var selectedDonation: Donation?
    @State private var lastShownDonationId: Int? // Track which donation was shown

//        // Add init to handle @State property
//        init(donor: Donor) {
//            _donor = State(initialValue: donor)
//        }
//
    
    var body: some View {
        Form {
            
            Section(header: Text("Personal Information")) {
                if let salutation = donor.salutation {
                    LabeledContent("Salutation", value: salutation)
                }
                if let firstName = donor.firstName {
                    LabeledContent("First Name", value: firstName)
                }
                if let lastName = donor.lastName {
                    LabeledContent("Last Name", value: lastName)
                }
                if let jewishName = donor.jewishName {
                    LabeledContent("Jewish Name", value: jewishName)
                }
                if let companyName = donor.company, !companyName.isEmpty {
                    LabeledContent("Company Name", value: companyName)
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
                if let addl_line1 = donor.addl_line {
                    LabeledContent("Address Line 2", value: addl_line1)
                }
                if let suite = donor.suite {
                    LabeledContent("Suite Number", value: suite)
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
            
                // Modified Donations section with async loading
            Section(header: Text("Donations")) {
                
                DonationsListView(
                    isLoadingDonations: isLoadingDonations,
                    donationsError:     donationsError,
                    donorDonations:     donorDonations,
                    onReload: {
                        Task {
                            await loadDonations()
                        }
                    },
                    onDonationSelected: { donation in
                        print("🔥 Donation selected: \(donation)")
                        selectedDonation = donation
                        lastShownDonationId = donation.id
                        showingDonationDetail = true
                    }
                )
            }
        }
        .navigationTitle("Donor Details")
        .navigationDestination(for: String.self) { stringValue in
            VStack {
                Text("String Handler View")
                    .font(.title)
                Text("Received string: \(stringValue)")
                    .padding()
            }
            .navigationTitle("String Handler")
        }
        .sheet(isPresented: $showingEditSheet) {
//            NavigationView {
            DonorEditView(mode: .edit(donor), donor: $donor)
//            }
        }
        .sheet(isPresented: $showingTestSheet) {
            NavigationView {
                VStack {
                    Text("Test Sheet Works!")
                        .font(.title)
                        .padding()
                    
                    Button("Dismiss") {
                        showingTestSheet = false
                    }
                    .padding()
                }
                .navigationTitle("Test Sheet")
            }
        }
        .sheet(isPresented: $showingTextView) {
            NavigationView {
                VStack {
                    Text("This is a simple text view destination")
                        .font(.title)
                        .padding()
                    
                    Button("Dismiss") {
                        showingTextView = false
                    }
                    .padding()
                }
                .navigationTitle("Text View")
            }
        }
        .sheet(isPresented: $showingStringView) {
            NavigationView {
                VStack {
                    Text("String Handler View")
                        .font(.title)
                    Text("Received string: test-string")
                        .padding()
                    
                    Button("Dismiss") {
                        showingStringView = false
                    }
                    .padding()
                }
                .navigationTitle("String Handler")
            }
        }
        .sheet(isPresented: $showingDonationDetail) {
            if let donation = selectedDonation {
                DonationDetailView(donation: donation)
                    .environmentObject(donorObject)
            }
        }
        .onChange(of: showingDonationDetail) { isPresented in
            // When the donation detail sheet is dismissed, refresh that specific donation
            if !isPresented, let donationId = lastShownDonationId {
                print("🔄 Donation detail sheet dismissed, updating donation \(donationId)...")
                Task {
                    await updateSingleDonation(donationId)
                }
                lastShownDonationId = nil
            }
        }
        .onChange(of: donor, initial: true) { oldValue, newValue in
            print("**** Donor changed in On Change: \(newValue) \n \(oldValue)")
             Task {
                 await loadDonations()
             }
         }

    }
    
        // Modified loadDonations to be async
        private func loadDonations() async {
            print("**** Loading Donations for \(donor)")
            
            guard let donorId = donor.id else { return }
            // Reset states
            await MainActor.run {
                isLoadingDonations = true
                donationsError = nil
                donorDonations = []
            }
            
            do {
                try await donationObject.loadDonationsForDonor(donorId: donorId)
                await MainActor.run {
                    self.donorDonations = donationObject.donations
                    self.isLoadingDonations = false
                }
            } catch {
                await MainActor.run {
                    self.donationsError = "Failed to load donations: \(error.localizedDescription)"
                    self.isLoadingDonations = false
                    self.donorDonations = []
                }
            }
        }

    // Add method to update a single donation
    private func updateSingleDonation(_ donationId: Int) async {
        do {
            // Get the fresh donation from database
            guard let updatedDonation = try await donationObject.getDonation(donationId) else {
                print("❌ Could not find donation with ID: \(donationId)")
                return
            }
            
            await MainActor.run {
                // Find and update the donation in our local array
                if let index = donorDonations.firstIndex(where: { $0.id == donationId }) {
                    donorDonations[index] = updatedDonation
                    print("✅ Updated single donation: \(updatedDonation.amount)")
                }
            }
        } catch {
            print("💥 Error updating single donation: \(error)")
        }
    }

        // Modified to use async/await properly
    private func loadDonationsold() async {
            guard let donorId = donor.id else { return }
            // Reset states
            isLoadingDonations = true
            donationsError = nil
            donorDonations = []
//            Task {
                do {
                    try await donationObject.loadDonationsForDonor(donorId: donorId)
                    await MainActor.run {
                        self.donorDonations = donationObject.donations
                        self.isLoadingDonations = false
                    }
                } catch {
                    await MainActor.run {
                        self.donationsError = "Failed to load donations: \(error.localizedDescription)"
                        self.isLoadingDonations = false
                    }
                }
//            }
        }

}
        // MARK: - Preview
//        #Preview {
//            // Create a sample donor with all fields populated
//            let sampleDonor = Donor(
//                uuid: "123",
//                salutation: "Mr.",
//                firstName: "John",
//                lastName: "Doe",
//                jewishName: "Yaakov",
//                address: "123 Main Street",
//                city: "New York",
//                state: "NY",
//                zip: "10001",
//                email: "john@example.com",
//                phone: "(555) 123-4567",
//                notes: "Regular donor"
//            )
//            
//            return NavigationView {
//                DonorDetailView(donor: sampleDonor)
//                    .environmentObject(DonorObjectClass())
//            }
//        }