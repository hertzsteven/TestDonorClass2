//
//  PrintReceiptView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/7/25.
//

import SwiftUI

struct PrintReceiptView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let receipt: OldReceipt
    let onCompletion: () -> Void
    
    var body: some View {
        VStack {
            Text("Print Receipt")
                .font(.title)
            
            Image(systemName: "printer")
                .font(.system(size: 50))
                .padding()
            
            Text("Preparing document for printing...")
                .padding()
            
            Button("Generate & Print Receipt") {
                    // Convert the date to string using DateFormatter
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                let dateString = dateFormatter.string(from: receipt.date)
                
                // CREATE: DonationInfo with address (for now using placeholder since we don't have donor access here)
                let donation = DonationInfo(
                    donorName: receipt.donorName,
                    donationAmount: receipt.total,
                    date: dateString,
                    donorAddress: nil,  // TODO: Get from donor record
                    donorCity: nil,     // TODO: Get from donor record
                    donorState: nil,    // TODO: Get from donor record
                    donorZip: nil       // TODO: Get from donor record
                )
                let receiptPrintService = ReceiptPrintingService()
                receiptPrintService.printReceipt(for: donation) {
                    self.presentationMode.wrappedValue.dismiss()
                    onCompletion()
                }
            }
            .padding()
        }
    }
}

struct CampaignPickerView: View {
    @EnvironmentObject var campaignObject: CampaignObjectClass
    @Binding var selectedCampaign: Campaign?
    
    var body: some View {
        Section(header: Text("Campaign")) {
            Picker("Campaign", selection: $selectedCampaign) {
                Text("None").tag(nil as Campaign?)
                    //
                ForEach(campaignObject.campaigns.filter { $0.id ?? 100 > 99 }) { campaign in
                        //                    ForEach(campaignObject.campaigns) { campaign in
                    Text(campaign.name).tag(campaign  as Campaign?)
                }
            }
        }
    }
}

struct IncentivePickerView: View {
    @EnvironmentObject var incentiveObject: DonationIncentiveObjectClass
    @Binding var selectedIncentive: DonationIncentive?
    
    var body: some View {
        Section(header: Text("Donation Incentive")) {
            Picker("Incentive", selection: $selectedIncentive) {
                Text("None").tag(DonationIncentive?.none)
                ForEach(incentiveObject.incentives.filter { $0.status == .active }) { incentive in
                    Text("\(incentive.name) ($\(String(format: "%.2f", incentive.dollarAmount)))").tag(DonationIncentive?.some(incentive))
                }
            }
        }
    }
}