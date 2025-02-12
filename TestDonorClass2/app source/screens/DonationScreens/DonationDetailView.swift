import SwiftUI

struct DonationDetailView: View {
    // Properties
    let donation: Donation
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @EnvironmentObject var donorObject: DonorObjectClass
    @State private var donor: Donor?
    @State private var isLoadingDonor = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section(header: Text("Amount and Status")) {
                LabeledContent("Amount", value: "$\(String(format: "%.2f", donation.amount))")
                LabeledContent("Payment Type", value: donation.donationType.rawValue)
                LabeledContent("Status", value: donation.paymentStatus.rawValue)
            }
            
            Section(header: Text("Date Information")) {
                LabeledContent("Donation Date", value: donation.donationDate, format: .dateTime)
                LabeledContent("Created", value: donation.createdAt, format: .dateTime)
                LabeledContent("Last Updated", value: donation.updatedAt, format: .dateTime)
            }
            
            Section(header: Text("Receipt Information")) {
                if let transactionNumber = donation.transactionNumber {
                    LabeledContent("Transaction #", value: transactionNumber)
                }
                if let receiptNumber = donation.receiptNumber {
                    LabeledContent("Receipt #", value: receiptNumber)
                }
                LabeledContent("Email Receipt", value: donation.requestEmailReceipt ? "Yes" : "No")
                LabeledContent("Printed Receipt", value: donation.requestPrintedReceipt ? "Yes" : "No")
            }
            
            if let paymentInfo = donation.paymentProcessorInfo {
                Section(header: Text("Payment Processing")) {
                    Text(paymentInfo)
                }
            }
            
            if let notes = donation.notes {
                Section(header: Text("Notes")) {
                    Text(notes)
                }
            }
            
            Section(header: Text("Additional Information")) {
                LabeledContent("Anonymous", value: donation.isAnonymous ? "Yes" : "No")
                if let donorId = donation.donorId {
                    LabeledContent("Donor ID", value: "\(donorId)")
                }
                if let campaignId = donation.campaignId {
                    LabeledContent("Campaign ID", value: "\(campaignId)")
                }
            }
        }
        .navigationTitle("Donation Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    loadDonorAndShowEdit()
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let donor = donor {
                NavigationView {
                    DonationEditView(donor: donor)
                }
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
            DonationDetailView(donation: Donation(amount: 100.0, donationType: .creditCard))
        }
    }
}
