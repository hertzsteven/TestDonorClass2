import SwiftUI

struct DonationDateEditView: View {
    let donation: Donation
    let onSave: (Donation) -> Void
    let donorName: String
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var donationObject: DonationObjectClass
    
    @State private var donationDate: Date
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingAlert = false
    @State private var amount: String
    @State private var donationType: DonationType
    @State private var paymentStatus: PaymentStatus
    
    // UPDATE: Initializer to accept donorName
    init(donation: Donation, donorName: String, onSave: @escaping (Donation) -> Void) {
        self.donation      = donation
        self.donorName     = donorName
        self.onSave        = onSave
        _donationDate      = State(initialValue: donation.donationDate)
        _amount            = State(initialValue: String(format: "%.2f", donation.amount))
        _donationType      = State(initialValue: donation.donationType)
        _paymentStatus     = State(initialValue: donation.paymentStatus)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // NEW: Section to display donor or company name
//                Section(header: Text("DONOR INFORMATION")) {
//                    HStack {
//                        VStack {
//                            Spacer()
//                            HStack(alignment: .firstTextBaseline) {
//                                Text("Donor")
//                                Spacer()
//                                Text(donorName)
//                                    .foregroundColor(.secondary)
//                            }
//                            Spacer()
//                        }
//                    }
//                    .frame(height: 36)
//                }
                Section(header: Text("DONOR")) {
                    Text(donorName.uppercased())
                        .font(.headline)
                }
                .frame(height: 36)

                Section(header: Text("DONATION DATE")) {
                    DatePicker(
                        "Date",
                        selection: $donationDate,
                        displayedComponents: [.date]        // time wheels removed
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                }

                Section(header: Text("AMOUNT")) {           // NEW
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("PAYMENT TYPE")) {     // NEW
                    Picker("Payment Type", selection: $donationType) {
                        ForEach(DonationType.allCases, id: \.self) { type in
                            Text(type.rawValue.uppercased()).tag(type)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section(header: Text("STATUS")) {           // NEW
                    Picker("Status", selection: $paymentStatus) {
                        ForEach(PaymentStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.uppercased()).tag(status)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle("Edit Donation") // UPDATE: More generic title
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
        await MainActor.run { isLoading = true }
        
        // Build updated donation
        var updatedDonation = donation
        updatedDonation.donationDate  = donationDate
        updatedDonation.updatedAt     = Date()

        if let newAmount = Double(amount) {
            updatedDonation.amount = newAmount
        }
        updatedDonation.donationType  = donationType
        updatedDonation.paymentStatus = paymentStatus

        do {
            try await donationObject.updateDonation(updatedDonation)
            await MainActor.run {
                isLoading = false
                onSave(updatedDonation)             // already in place
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
            donation: Donation(amount: 186.0, donationType: .other),
            donorName: "JOHN APPLESEED"
        ) { _ in }
    }
}
