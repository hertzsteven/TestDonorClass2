import SwiftUI

struct DonationsListView: View {
    let isLoadingDonations: Bool
    let donationsError: String?
    let donorDonations: [Donation]
    let onReload: () -> Void
    let onDonationSelected: ((Donation) -> Void)?
    
    var body: some View {
        if isLoadingDonations {
            HStack {
                Spacer()
                ProgressView()
                    .padding()
                Spacer()
            }
        } else if let error = donationsError {
            HStack {
                Text(error)
                    .foregroundColor(.red)
                Spacer()
                Button(action: onReload) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        } else if donorDonations.isEmpty {
            Text("No donations found")
                .foregroundColor(.secondary)
        } else {
            ForEach(donorDonations) { donation in
                Button(action: {
                    print("🔥 Button tapped for donation: \(donation.amount)")
                    onDonationSelected?(donation)
                }) {
                    DonationListItemView(donation: donation)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct DonationDetailsView: View {
    let donation: Donation
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Form {
            Section(header: Text("Donation Details")) {
                LabeledContent("Amount", value: String(format: "$%.2f", donation.amount))
                LabeledContent("Date", value: donation.donationDate.formatted())
                LabeledContent("Type", value: donation.donationType.rawValue)
//                if let campaign = donation.campaignId {
//                    LabeledContent("Campaign", value: campaign)
//                }
            }
            
            Section(header: Text("Receipt Status")) {
                LabeledContent("Email Receipt", value: donation.requestEmailReceipt ? "Requested" : "Not Requested")
                LabeledContent("Print Receipt", value: donation.requestPrintedReceipt ? "Requested" : "Not Requested")
            }
            
            if let notes = donation.notes {
                Section(header: Text("Notes")) {
                    Text(notes)
                }
            }
        }
        .navigationTitle("Donation Details")
        .navigationBarBackButtonHidden(true)
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
    }
}