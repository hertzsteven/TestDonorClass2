import SwiftUI

struct DonationDateEditView: View {
    let donation: Donation
    let onSave: (Donation) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var donationObject: DonationObjectClass
    
    @State private var donationDate: Date
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingAlert = false
    
    init(donation: Donation, onSave: @escaping (Donation) -> Void) {
        self.donation = donation
        self.onSave = onSave
        self._donationDate = State(initialValue: donation.donationDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("DONATION DATE")) {
                    DatePicker(
                        "Date",
                        selection: $donationDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                }
                
                Section(header: Text("CURRENT DETAILS")) {
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
            }
            .navigationTitle("Edit Donation Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveDonation()
                        }
                    }
                    .disabled(isLoading)
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func saveDonation() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Create updated donation with new date
        var updatedDonation = donation
        updatedDonation.donationDate = donationDate
        updatedDonation.updatedAt = Date()
        
        do {
            try await donationObject.updateDonation(updatedDonation)
            
            await MainActor.run {
                isLoading = false
                onSave(updatedDonation)
                dismiss()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}

// MARK: - Preview
struct DonationDateEditView_Previews: PreviewProvider {
    static var previews: some View {
        DonationDateEditView(
            donation: Donation(amount: 186.0, donationType: .other)
        ) { _ in }
    }
}