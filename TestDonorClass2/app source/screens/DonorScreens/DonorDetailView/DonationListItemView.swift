import SwiftUI

struct DonationListItemView: View {
    let donation: Donation
    
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
            }
            if let campaign = donation.campaignId {
                Text("Campaign: \(campaign)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text("Type: \(donation.donationType.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

