import SwiftUI

struct DonationListItemView: View {
    let donation: Donation
    @State private var campaignName: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("$\(donation.amount, specifier: "%.2f")")
                    .font(.headline)
                Spacer()
                Text(donation.paymentStatus.rawValue)
                    .font(.caption)
                    .padding(4)
                    .background(donation.paymentStatus == .completed ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .cornerRadius(4)
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 24))
            }
            if let campaignId = donation.campaignId {
                Text("Campaign: \(campaignName ?? "#\(campaignId)")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text("Donation Type: \(donation.donationType.displayName)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Date: \(donation.donationDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .task {
            if let campaignId = donation.campaignId {
                campaignName = await CampaignNameService.shared.name(forCampaignId: campaignId)
            }
        }
    }
}