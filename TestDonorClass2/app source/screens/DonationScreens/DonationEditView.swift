    //
    //  DonationEditView.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz
    //

    import SwiftUI

    private struct CampaignPickerView: View {
        @EnvironmentObject var campaignObject: CampaignObjectClass
        @Binding var selectedCampaign: Campaign?
        
        var body: some View {
            Section(header: Text("Campaign")) {
                Picker("Campaign", selection: $selectedCampaign) {
                    Text("None").tag(Campaign?.none)
                    ForEach(campaignObject.campaigns.filter { $0.status == .active }) { campaign in
                        Text(campaign.name).tag(Campaign?.some(campaign))
                    }
                }
            }
        }
    }

    private struct IncentivePickerView: View {
        @EnvironmentObject var incentiveObject: DonationIncentiveObjectClass
        @Binding var selectedIncentive: DonationIncentive?
        
        var body: some View {
            Section(header: Text("Donation Incentive")) {
                Picker("Incentive", selection: $selectedIncentive) {
                    Text("None").tag(DonationIncentive?.none)
                    ForEach(incentiveObject.incentives.filter { $0.status == .active }) { incentive in
                        Text("\(incentive.name) ($\(incentive.dollarAmount))").tag(DonationIncentive?.some(incentive))
                    }
                }
            }
        }
    }

    struct DonationEditView: View {
        let donor: Donor
        @Environment(\.presentationMode) var presentationMode
        @EnvironmentObject var donationObject: DonationObjectClass
        @EnvironmentObject var campaignObject: CampaignObjectClass
        @EnvironmentObject var incentiveObject: DonationIncentiveObjectClass
            // Add defaultSettings property
            @State private var defaultSettings: DefaultDonationSettings?



            
            @State private var amount: String = ""
            @State private var donationType: DonationType = .creditCard
            @State private var notes: String = ""
            @State private var isAnonymous: Bool = false
            @State private var requestEmailReceipt: Bool = false
            @State private var requestPrintedReceipt: Bool = false
            @State private var showingAlert = false
            @State private var alertMessage = ""
            
                // Add new state properties
                @State private var selectedCampaign: Campaign?
                @State private var selectedIncentive: DonationIncentive?

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
                    
                    CampaignPickerView(selectedCampaign: $selectedCampaign)
                    IncentivePickerView(selectedIncentive: $selectedIncentive)

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
                
                .onAppear {
                    // Load campaigns and incentives when view appears
                    Task {
                        await campaignObject.loadCampaigns()
                        await incentiveObject.loadIncentives()
                        
                            // Load and apply default settings
                            await loadAndApplyDefaultSettings()

                    }
                }

            }
            // Add function to load and apply default settings
            private func loadAndApplyDefaultSettings() async {
                // TODO: Load default settings from your repository
                // For now, we'll create a sample default settings
                let settings = DefaultDonationSettings(
                    amount: 100,
                    donationType: .creditCard,
                    requestEmailReceipt: true,
                    requestPrintedReceipt: false
                )
                
                await MainActor.run {
                    // Apply the settings to our form
                    self.amount = String(settings.amount ?? 0)
                    self.donationType = settings.donationType ?? .creditCard
                    self.requestEmailReceipt = settings.requestEmailReceipt
                    self.requestPrintedReceipt = settings.requestPrintedReceipt
                    if let campaignId = settings.campaignId {
                        self.selectedCampaign = campaignObject.campaigns.first(where: { $0.id == campaignId })
                    }
                    if let incentiveId = settings.donationIncentiveId {
                        self.selectedIncentive = incentiveObject.incentives.first(where: { $0.id == incentiveId })
                    }
                    self.notes = settings.notes ?? ""
                    self.isAnonymous = settings.isAnonymous
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
                    campaignId: selectedCampaign?.id,
                    donationIncentiveId: selectedIncentive?.id,
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
                .environmentObject(CampaignObjectClass())
                .environmentObject(DonationIncentiveObjectClass())
            }
        }
