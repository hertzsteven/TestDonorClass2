import SwiftUI

struct DonationDetailView: View {
    // Properties
    let originalDonation: Donation
    @State private var donation: Donation
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @EnvironmentObject var donorObject: DonorObjectClass
    @State private var donor: Donor?
    @State private var isLoadingDonor = false
    @State private var errorMessage: String?
    @State private var donorName: String = "Loading..." // NEW: State to hold donor/company name
    
    // Date formatters to match the screenshot
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy, h:mm a"
        return formatter
    }
    // Date formatters to match the screenshot
    private var dateOnlyFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        return formatter
    }
    
    init(donation: Donation) {
        self.originalDonation = donation
        self._donation = State(initialValue: donation)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // NEW: Section to display donor or company name
                Section(header: Text("DONOR INFORMATION")) {
                    HStack {
                        VStack {
                            Spacer()
                            HStack(alignment: .firstTextBaseline) {
                                Text("Donor")
                                Spacer()
                                Text(donorName)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .frame(height: 36)
                }
                
                Section(header: Text("AMOUNT AND STATUS")) {
                    HStack {
                        Text("Amount")
                        Spacer()
                        Text("$\(String(format: "%.2f", donation.amount))")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Payment Type")
                        Spacer()
                        Text(donation.donationType.rawValue.uppercased())
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(donation.paymentStatus.rawValue.uppercased())
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("DATE INFORMATION")) {
                    HStack {
                        Text("Donation Date")
                        Spacer()
                        Text(dateOnlyFormatter.string(from: donation.donationDate))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(dateOnlyFormatter.string(from: donation.createdAt))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Updated")
                        Spacer()
                        Text(dateOnlyFormatter.string(from: donation.updatedAt))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("RECEIPT INFORMATION")) {
                    HStack {
                        Text("Email Receipt")
                        Spacer()
                        Text(donation.requestEmailReceipt ? "Yes" : "No")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Printed Receipt")
                        Spacer()
                        Text(donation.requestPrintedReceipt ? "Yes" : "No")
                            .foregroundColor(.secondary)
                    }
                    
                    if let transactionNumber = donation.transactionNumber {
                        HStack {
                            Text("Transaction #")
                            Spacer()
                            Text(transactionNumber)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let receiptNumber = donation.receiptNumber {
                        HStack {
                            Text("Receipt #")
                            Spacer()
                            Text(receiptNumber)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("ADDITIONAL INFORMATION")) {
//                    HStack {
//                        Text("Anonymous")
//                        Spacer()
//                        Text(donation.isAnonymous ? "Yes" : "No")
//                            .foregroundColor(.secondary)
//                    }
                    
                    if let campaignId = donation.campaignId {
                        HStack {
                            Text("Campaign")
                            Spacer()
                            Text("#\(campaignId)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Donation Type")
                        Spacer()
                        Text(donation.donationType.rawValue.uppercased())
                            .foregroundColor(.secondary)
                    }
                }
                
                if let paymentInfo = donation.paymentProcessorInfo {
                    Section(header: Text("PAYMENT PROCESSING")) {
                        Text(paymentInfo)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let notes = donation.notes {
                    Section(header: Text("NOTES")) {
                        Text(notes)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Donation Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                }
            }
            .task {
                await loadDonorName() // NEW: Load donor/company name when view appears
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            // UPDATE: Pass the fetched donorName to the edit view
            DonationDateEditView(donation: donation, donorName: donorName) { updatedDonation in
                self.donation = updatedDonation        // keep UI in sync
                showingEditSheet = false
            }
        }
        .alert("Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // NEW: Function to load donor or company name
    private func loadDonorName() async {
        // Check if this is an anonymous donation
        guard let donorId = donation.donorId, donorId > 0 else {
            donorName = "Anonymous Donor"
            return
        }
        
        do {
            // Create a donor repository to fetch the donor
            let donorRepository = try DonorRepository()
            if let donor = try await donorRepository.getOne(donorId) {
                // Show company name if available, otherwise show donor's full name
                if let company = donor.company, !company.isEmpty {
                    donorName = company
                } else {
                    donorName = donor.fullName
                }
            } else {
                donorName = "Unknown Donor"
            }
        } catch {
            donorName = "Error Loading Donor"
            print("Error loading donor: \(error)")
        }
    }
    
    private func loadDonorAndShowEdit() {
        guard let donorId = donation.donorId else {
            errorMessage = "No donor associated with this donation"
            return
        }
        
        
        Task {
            await MainActor.run {
                isLoadingDonor = true
            }
            do {
                donor = try await donorObject.getDonor(donorId)
                if donor != nil {
                    await MainActor.run {
                        showingEditSheet = true
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Could not find donor with ID \(donorId)"
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            await MainActor.run {
                isLoadingDonor = false
            }
        }
    }
}

// MARK: - Preview Provider
struct DonationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DonationDetailView(donation: Donation(amount: 186.0, donationType: .other))
        }
    }
}