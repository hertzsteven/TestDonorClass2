//
//  DonationEditView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz
//

import SwiftUI

struct DonationEditView: View {
    let donor: Donor
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var donationObject: DonationObjectClass
    
    @State private var amount: String = ""
    @State private var donationType: DonationType = .creditCard
    @State private var notes: String = ""
    @State private var isAnonymous: Bool = false
    @State private var requestEmailReceipt: Bool = false
    @State private var requestPrintedReceipt: Bool = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var isValidAmount: Bool {
        guard let doubleValue = Double(amount) else { return false }
        return doubleValue > 0
    }
    
    var body: some View {
        Form {
            Section(header: Text("Donation Details")) {
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                
                Picker("Type", selection: $donationType) {
                    ForEach(DonationType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }
            
            Section(header: Text("Receipt Options")) {
                Toggle("Request Email Receipt", isOn: $requestEmailReceipt)
                Toggle("Request Printed Receipt", isOn: $requestPrintedReceipt)
                Toggle("Anonymous Donation", isOn: $isAnonymous)
            }
            
            Section(header: Text("Additional Information")) {
                TextEditor(text: $notes)
                    .frame(height: 100)
            }
        }
        .navigationTitle("New Donation")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveDonation()
                }
                .disabled(!isValidAmount)
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveDonation() {
        guard let amountValue = Double(amount) else {
            alertMessage = "Please enter a valid amount"
            showingAlert = true
            return
        }
        
        let donation = Donation(
            donorId: donor.id,
            amount: amountValue,
            donationType: donationType,
            paymentStatus: .pending,
            requestEmailReceipt: requestEmailReceipt,
            requestPrintedReceipt: requestPrintedReceipt,
            notes: notes.isEmpty ? nil : notes,
            isAnonymous: isAnonymous,
            donationDate: Date()
        )
        
        // Add donation using DonationObjectClass (we'll create this next)
        Task {
            do {
                try await donationObject.addDonation(donation)
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        DonationEditView(donor: Donor(
            firstName: "John",
            lastName: "Doe"
        ))
        .environmentObject(DonorObjectClass())
    }
}
