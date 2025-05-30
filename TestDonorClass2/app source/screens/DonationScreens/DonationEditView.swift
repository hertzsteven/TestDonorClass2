    //
    //  DonationEditView.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz
    //

    import SwiftUI
    import MessageUI

    struct DonationEditView: View {
        let donor: Donor
        @Environment(\.presentationMode) var presentationMode
        @EnvironmentObject var donationObject: DonationObjectClass
        @EnvironmentObject var campaignObject: CampaignObjectClass
        @EnvironmentObject var incentiveObject: DonationIncentiveObjectClass
        @EnvironmentObject var defaultDonationSettingsViewModel: DefaultDonationSettingsViewModel
        
        // Add defaultSettings property
        @State private var defaultSettings      : DefaultDonationSettings?
        
        @State private var amountText: String = ""
        @State private var amount               : String = ""
        @State private var donationType         : DonationType = .creditCard
        @State private var notes                : String = ""
        @State private var isAnonymous          : Bool = false
        @State private var requestEmailReceipt  : Bool = false
        @State private var requestPrintedReceipt: Bool = false
        @State private var campaignId           : Int? = nil
        @State private var incentiveId          : Int? = nil
        
        @State private var showErrorAlert: Bool = false
        @State private var showingAlert         = false
        @State private var alertMessage         = ""
        @State private var alertTitle           = ""  // Add this line
        @State private var isError              = false   // Add this line
        
        @State private var defaultsLoaded: Bool = false
        
        // Add new state properties
        @State private var selectedCampaign: Campaign?
        @State private var selectedIncentive: DonationIncentive?
        
        // Add state for showing mail view
        @State private var isShowingMailView = false
        @State private var isShowingPrintView = false
        @State private var currentReceipt: OldReceipt?
        
                
        private var isValidAmount: Bool {
    //        guard let doubleValue = Double(amount) else { return false }
            return twoDecimalPlaces  > 0
        }
        
        private var formattedAmount: Binding<String> {
            Binding(
                get: { self.amount },
                set: { newValue in
                    if let number = Double(newValue) {
    //                    self.amount = String(format: "%.2f", number)
                    } else if newValue.isEmpty {
                        self.amount = ""
                    }
                }
            )
        }
        @State private var twoDecimalPlaces = 0.0
         
        let twoDecimalFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
//            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            return formatter
        }()
         
        var body: some View {
            
            VStack {
                HStack {
                    if let firstName = donor.firstName, let lastName = donor.lastName {
                        Text("For " + firstName + " " + lastName )
                            .font(.title2)
                            //                        .font(.system(size: 38)) // Set font size to 38
                            //                        .font(systemFont(size: 24))
                    }
                    
                    
                    Spacer()
                    if defaultsLoaded {
                        Label("Defaults Loaded", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.cyan)
                    }
                    
                }  .padding()
                
                Form {
    //                Section(header: Text("Two Decimal Places")) {
    //                    // Formatted with exactly two decimal places
    //                    TextField("Enter amount", value: $twoDecimalPlaces, formatter: twoDecimalFormatter)
    //                        .keyboardType(.decimalPad)
    //                    Text("Value: \(twoDecimalPlaces, specifier: "%.2f")")
    //                }
                    
                    
                    Section(header: Text("Donation Details")) {
                        
                        TextField("Enter amount", value: $twoDecimalPlaces, formatter: twoDecimalFormatter)
                            .keyboardType(.decimalPad)
                        
    //                    TextField("Amount", text: formattedAmount)
    //                        .keyboardType(.decimalPad)
    //                        .onChange(of: amount) { newValue in
    //                            if newValue.isEmpty { return }
    //                            if let number = Double(newValue) {
    //                                self.amount = String(format: "%.2f", number)
    //                            }
    //                        }
                        
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
                            //                        Toggle("Anonymous Donation", isOn: $isAnonymous)
                    }
                    
                    Section(header: Text("Additional Information")) {
                        TextEditor(text: $notes)
                            .frame(height: 100)
                    }
                    
                    
                }
                
                
                .navigationTitle("New Donation")
                .navigationBarBackButtonHidden(true)
                
                .toolbar {
                    toolBarCancelSave()
                }
                
    //            .toolbar
    //                ToolbarItem(placement: .bottomBar) {
    //                    if donorObject.loadingState == .loaded {
    //                        Picker("Search Mode", selection: $searchMode) {
    //                            ForEach(SearchMode.allCases, id: \.self) { mode in
    //                                Text(mode.rawValue).tag(mode)
    //                            }
    //                        }
    //                        .pickerStyle(.segmented)
    //                        .padding(.horizontal)
    //                        .padding(.vertical, 8)
    //                    }
    //                }
    //
                
                
    //            .toolbar {
    //                ToolbarItem(placement: .navigationBarLeading) {
    //                    Button("Cancel") {
    //                        presentationMode.wrappedValue.dismiss()
    //                    }
    //                }
    //                ToolbarItem(placement: .navigationBarTrailing) {
    //                    Button("Save") {
    //                        Task {
    //                            await saveDonation()
    //                        }
    //                    }
    //                    .disabled(!isValidAmount)
    //                }
    //            }

                .alert("No email", isPresented: $showErrorAlert) {
                    Button("OK", role: .cancel) {
                        if requestPrintedReceipt {
                            isShowingPrintView = true
                            showErrorAlert = false
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                
                .alert(alertTitle, isPresented: $showingAlert) {
                    Button("OK", role: .cancel) {
                            // Dismiss view if it was a success alert
                        if !isError {
                            if requestEmailReceipt {
                                if MFMailComposeViewController.canSendMail() {
                                    isShowingMailView = true
                                } else {
                                    alertTitle = "Email Not Available"
                                    alertMessage = "Email is not set up on this device. The donation was saved successfully."
                                    isError = true
                                    showErrorAlert = true
//                                    presentationMode.wrappedValue.dismiss()
                                }
                            } else if requestPrintedReceipt {
                                    // only requesting a printed receipt
                                isShowingPrintView = true
                            }
                            else {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                } message: {
                    Text(alertMessage)
                }
                
              
                .sheet(isPresented: $isShowingPrintView) {
                    doPrintReceipt()
                }
                .interactiveDismissDisabled(true)
                
                .sheet(isPresented: $isShowingMailView) {
                    doMailReceipt()
                }
                .interactiveDismissDisabled(true)
                
                
                .onAppear {
                    Task {await doOnAppearProcess() }
                }
                
                    //  TODO:  Get rid of soon just here hust in case I needed it
                /*
                .onAppear {
                        // Load campaigns and incentives when view appears
                    Task {
                        await campaignObject.loadCampaigns()
                        await incentiveObject.loadIncentives()
                        
                            // Load and apply default settings
                        await loadAndApplyDefaultSettings()
                        
                    }
                }
                */
                
            }
            
        }
        
        // Add function to load and apply default settings
        private func loadAndApplyDefaultSettings() async {
                // TODO: Load default settings from your repository
                // For now, we'll create a sample default settings
            
            if         defaultDonationSettingsViewModel.settings.amount != nil
                        || defaultDonationSettingsViewModel.settings.donationType != nil
                        || defaultDonationSettingsViewModel.settings.campaignId != nil
                        || defaultDonationSettingsViewModel.settings.donationIncentiveId != nil
                        || defaultDonationSettingsViewModel.settings.requestEmailReceipt
                        || defaultDonationSettingsViewModel.settings.requestPrintedReceipt {
                defaultsLoaded.toggle()
            }
            
            let settings = DefaultDonationSettings(
                amount: defaultDonationSettingsViewModel.settings.amount,
                donationType: defaultDonationSettingsViewModel.settings.donationType,
                campaignId: defaultDonationSettingsViewModel.settings.campaignId,
                donationIncentiveId: defaultDonationSettingsViewModel.settings.donationIncentiveId,
                requestEmailReceipt: defaultDonationSettingsViewModel.settings.requestEmailReceipt,
                requestPrintedReceipt: defaultDonationSettingsViewModel.settings.requestPrintedReceipt
            )
            
            await MainActor.run {
                    // Apply the settings to our form
                self.twoDecimalPlaces  = settings.amount ?? 0.00
                self.donationType = settings.donationType ?? .creditCard
                self.requestEmailReceipt = settings.requestEmailReceipt
                self.requestPrintedReceipt = settings.requestPrintedReceipt
                self.campaignId = settings.campaignId
                self.incentiveId = settings.donationIncentiveId
                dump(settings)
                print("\(settings)")
                print("\(self.campaignId ?? 0)")
                print("\(self.campaignId ?? 0)")
                
                if let campaignId = settings.campaignId {
                    self.selectedCampaign = campaignObject.campaigns.first(where: { $0.id == campaignId })
                }
                if let incentiveId = settings.donationIncentiveId {
                    self.selectedIncentive = incentiveObject.incentives.first(where: { $0.id == incentiveId })
                }
                    //               self.notes = settings.notes ?? ""
                    //                self.isAnonymous = settings.isAnonymous
            }
        }
        
        private func saveDonation() async {
    //        guard let amountValue = Double(amount) else {
    //            await MainActor.run {
    //                alertTitle = "Error"
    //                alertMessage = "Please enter a valid amount"
    //                isError = true
    //                showingAlert = true
    //            }
    //            return
    //        }
            
            let donation = Donation(
                donorId: donor.id,
                campaignId: selectedCampaign?.id,
                donationIncentiveId: selectedIncentive?.id,
                amount: twoDecimalPlaces,
    //            amount: amountValue,
                donationType: donationType,
                paymentStatus: .completed,
                requestEmailReceipt: requestEmailReceipt,
                requestPrintedReceipt: requestPrintedReceipt,
                notes: notes.isEmpty ? nil : notes,
                isAnonymous: isAnonymous,
                donationDate: Date()
            )
            
            Task {
                do {
                    try await donationObject.addDonation(donation)
                    
                    await MainActor.run {
                        
                            //                        if requestPrintedReceipt {
                            ////                            isShowingPrintView = true
                            //                            let donation = DonationInfo(donorName: "John Doe", donationAmount: 100.0, date: "Jan 8, 2025")
                            //                            let receiptPrintService = ReceiptPrintingService()
                            //                            receiptPrintService.printReceipt(for: donation)
                            //                            presentationMode.wrappedValue.dismiss()
                            //                        } else if requestEmailReceipt {
                            //                            if MFMailComposeViewController.canSendMail() {
                            //                                isShowingMailView = true
                            //                            } else {
                            //                                alertTitle = "Email Not Available"
                            //                                alertMessage = "Email is not set up on this device. The donation was saved successfully."
                            //                                isError = true
                            //                                showingAlert = true
                            //
                            //
                            //                            }
                            //
                            //
                            //                        } else {
                        alertTitle = "Success"
                        alertMessage = "Donation of $\(String(format: "%.2f", twoDecimalPlaces)) successfully saved!"
                        isError = false
                        showingAlert = true
                            //                        }
                    }
                } catch {
                    await MainActor.run {
                        alertTitle = "Error"
                        alertMessage = error.localizedDescription
                        isError = true
                        showingAlert = true
                    }
                }
            }
        }
    }


    //  MARK: -  Extension For the Sheets and Alerts
    extension DonationEditView {
        
        fileprivate var receipt: OldReceipt {
            return OldReceipt(
                date: Date(),
                total: Double(twoDecimalPlaces) ?? 0,
                items: [
                    OldReceiptItem(
                        name: selectedCampaign?.name ?? "General Donation",
                        price: Double(twoDecimalPlaces) ?? 0
                    )
                ],
                donorName: "\(donor.firstName ?? "") \(donor.lastName ?? "") \(donor.company ?? "")",
                donationType: donationType.rawValue
            )
        }

        fileprivate func doPrintReceipt() -> PrintReceiptView {
            
            let onCompletion: () -> Void = {
                isShowingPrintView = false
                presentationMode.wrappedValue.dismiss()
            }
            
            return PrintReceiptView(receipt: receipt, onCompletion: onCompletion)
        }
        
        fileprivate func doMailReceipt() -> MailView {
            
            let emailRecipient: String = donor.email ?? ""
            
            let onCompletion: () -> Void = {
                if requestPrintedReceipt {
                    isShowingPrintView = true
                    isShowingMailView = false
                } else {
                    isShowingMailView = false
                    presentationMode.wrappedValue.dismiss()
                }
            }

            return MailView(receipt: receipt, emailRecipient: emailRecipient, onCompletion: onCompletion)
        }

        
            //  TODO:  Get rid of soon just here hust in case I needed it
        fileprivate func doMailReceiptOld() -> MailView {
                    
            return MailView(
                receipt: OldReceipt(
                    date: Date(),
                    total: Double(twoDecimalPlaces) ?? 0,
                    items: [
                        OldReceiptItem(
                            name: selectedCampaign?.name ?? "General Donation",
                            price: Double(twoDecimalPlaces) ?? 0
                        )
                    ],
                    donorName: "\(String(describing: donor.firstName)) \(String(describing: donor.lastName))",
                    donationType: donationType.rawValue
                ),
                emailRecipient: donor.email ?? "",
                onCompletion: {
                    
                    if requestPrintedReceipt {
                        isShowingPrintView = true
                            //                                let donation = DonationInfo(donorName: "John Doe", donationAmount: 100.0, date: "Jan 8, 2025")
                            //                                let receiptPrintService = ReceiptPrintingService()
                            //                                receiptPrintService.printReceipt(for: donation)
                        isShowingMailView = false
                            //                                presentationMode.wrappedValue.dismiss()
                    } else {
                        isShowingMailView = false
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
        
        fileprivate func doPrintReceiptOld() -> PrintReceiptView {
            return PrintReceiptView(
                receipt: OldReceipt(
                    date: Date(),
                    total: Double(twoDecimalPlaces) ?? 0,
                    items: [
                        OldReceiptItem(
                            name: selectedCampaign?.name ?? "General Donation",
                            price: Double(twoDecimalPlaces) ?? 0
                        )
                    ],
                    donorName: "\(donor.firstName) \(donor.lastName)",
                    donationType: donationType.rawValue
                ),
                onCompletion: {
                    isShowingPrintView = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        
        fileprivate func doPrintReceiptnewold() -> PrintReceiptView {
            
            let receipt = OldReceipt(
                date: Date(),
                total: Double(twoDecimalPlaces) ?? 0,
                items: [
                    OldReceiptItem(
                        name: selectedCampaign?.name ?? "General Donation",
                        price: Double(twoDecimalPlaces) ?? 0
                    )
                ],
                donorName: "\(donor.firstName ?? "") \(donor.lastName ?? "") \(donor.company ?? "")",
                donationType: donationType.rawValue
            )
            
            let onCompletion: () -> Void = {
                isShowingPrintView = false
                presentationMode.wrappedValue.dismiss()
            }
            
            return PrintReceiptView(receipt: receipt, onCompletion: onCompletion)
        }
         
    }

    // MARK: - Life Cycle Methods
    extension DonationEditView {

        fileprivate func doOnAppearProcess() async {
            await loadTheData()
        }
        
        fileprivate func doOnDisappearProcess() {
        }
        
        func loadTheData() async {
            do {
                await campaignObject.loadCampaigns()
                await incentiveObject.loadIncentives()
                    // Load and apply default settings
                await loadAndApplyDefaultSettings()
            } catch {
                print("Error: \(error)")
            }
        }
    }
//  MARK: -  funcs that build tool bar
extension DonationEditView  {
    
    @ToolbarContentBuilder
    func toolBarCancelSave() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Save") {
                Task {
                    await saveDonation()
                }
            }
            .disabled(!isValidAmount)
        }
    }
}
