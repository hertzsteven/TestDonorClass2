    //
    //  DonorDetailView.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 1/1/25.
    //

    import SwiftUI
    // MARK: - Detail View
struct DonorDetailView: View {
    let donor: Donor
    @State private var showingEditSheet = false
    @EnvironmentObject var donorObject: DonorObjectClass
    @EnvironmentObject var donationObject: DonationObjectClass
    @Environment(\.presentationMode) var presentationMode
    
        // Add state for donations and loading state
        @State private var donorDonations: [Donation] = []
        @State private var isLoadingDonations = true // Changed to true by default
        @State private var donationsError: String? = nil

    
    
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
            
                // Modified Donations section with async loading
            Section(header: Text("Donations")) {
                DonationsListView(
                    isLoadingDonations: isLoadingDonations,
                    donationsError: donationsError,
                    donorDonations: donorDonations,
                    onReload: {
                        Task {
                            await loadDonations()
                        }
                    }

                )
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
//            NavigationView {
                DonorEditView(mode: .edit(donor))
//            }
        }
            // Remove the existing .task modifier
            // Add onChange modifier to watch donor changes
        .onChange(of: donor, initial: true) { oldValue, newValue in
             Task {
                 await loadDonations()
             }
         }
//            .onAppear {
//                Task {
//                    await loadDonations()
//                }
//            }
    }
    
        // Modified loadDonations to be async
        private func loadDonations() async {
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
                }
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
        #Preview {
            // Create a sample donor with all fields populated
            let sampleDonor = Donor(
                uuid: "123",
                salutation: "Mr.",
                firstName: "John",
                lastName: "Doe",
                jewishName: "Yaakov",
                address: "123 Main Street",
                city: "New York",
                state: "NY",
                zip: "10001",
                email: "john@example.com",
                phone: "(555) 123-4567",
                notes: "Regular donor"
            )
            
            return NavigationView {
                DonorDetailView(donor: sampleDonor)
                    .environmentObject(DonorObjectClass())
            }
        }
