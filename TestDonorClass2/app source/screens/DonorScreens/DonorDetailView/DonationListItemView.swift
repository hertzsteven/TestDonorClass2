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
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 24))
            }
            if let campaign = donation.campaignId {
                Text("Campaign: #\(campaign)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text("Donation Type: \(donation.donationType.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Date: \(donation.donationDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}