import SwiftUI

struct DefaultDonationSettingsView: View {
    @EnvironmentObject  var viewModel: DefaultDonationSettingsViewModel
    @State private var showingError = false
    @EnvironmentObject var campaignObject: CampaignObjectClass
    @EnvironmentObject var incentiveObject: DonationIncentiveObjectClass
    @Environment(\.dismiss) var dismiss
    
    @State private var twoDecimalPlaces = 0.0 // {
//        didSet {
//            viewModel.settings.amount = twoDecimalPlaces
//        }
//    }
     
    let twoDecimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
//        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Default Amount")) {
                    HStack {
                        Text("$")
                        TextField("Enter amount",
                                  value: $twoDecimalPlaces,
                                  formatter: twoDecimalFormatter)
                        .keyboardType(.decimalPad)
                    
                    }
                }
                
                Section(header: Text("Default Payment Type")) {
                    Picker("Payment Type", selection: Binding(
                        get: { viewModel.settings.donationType ?? .creditCard },
                        set: { viewModel.settings.donationType = $0 }
                    )) {
                        ForEach(DonationType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Default Campaign")) {
                    Picker("Campaign", selection: Binding(
                        get: { campaignObject.campaigns.first(where: { $0.id == viewModel.settings.campaignId }) },
                        set: { viewModel.settings.campaignId = $0?.id }
                    )) {
                        Text("None").tag(Campaign?.none)
                        ForEach(campaignObject.campaigns.filter { $0.status == .active }) { campaign in
                            Text(campaign.name).tag(Campaign?.some(campaign))
                        }
                    }
                }
                
                Section(header: Text("Default Incentive")) {
                    Picker("Incentive", selection: Binding(
                        get: { incentiveObject.incentives.first(where: { $0.id == viewModel.settings.donationIncentiveId }) },
                        set: { viewModel.settings.donationIncentiveId = $0?.id }
                    )) {
                        Text("None").tag(DonationIncentive?.none)
                        ForEach(incentiveObject.incentives.filter { $0.status == .active }) { incentive in
                            Text("\(incentive.name) ($\(incentive.dollarAmount))").tag(DonationIncentive?.some(incentive))
                        }
                    }
                }
                
                Section(header: Text("Default Receipt Options")) {
                    Toggle("Request Email Receipt", isOn: $viewModel.settings.requestEmailReceipt)
                    Toggle("Request Printed Receipt", isOn: $viewModel.settings.requestPrintedReceipt)
//                    Toggle("Anonymous Donation", isOn: $viewModel.settings.isAnonymous)
                }
                
    //            Section(header: Text("Default Notes")) {
    //                TextEditor(text: Binding(
    //                    get: { viewModel.settings.notes ?? "" },
    //                    set: { viewModel.settings.notes = $0.isEmpty ? nil : $0 }
    //                ))
    //                .frame(height: 100)
    //            }
                
                Section {
                    Button("Save Default Settings") {
                        viewModel.settings.amount = twoDecimalPlaces
                        Task {
                            if await !viewModel.saveSettings() {
                                showingError = true
                            } else {
                                dismiss()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button("Clear All Defaults") {
                        Task {
                            viewModel.settings = DefaultDonationSettings()
                            await viewModel.saveSettings()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Default Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert("Error", isPresented: $showingError, presenting: viewModel.error) { _ in
            Button("OK") {
                viewModel.clearError()
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .onAppear {
            // Load campaigns and incentives when view appears
            twoDecimalPlaces = viewModel.settings.amount ?? 0.00
            Task {
                await campaignObject.loadCampaigns()
                await incentiveObject.loadIncentives()
            }
        }
    }
}
