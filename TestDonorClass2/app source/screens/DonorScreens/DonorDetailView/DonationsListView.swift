import SwiftUI

struct DonationsListView: View {
    let isLoadingDonations: Bool
    let donationsError: String?
    let donorDonations: [Donation]
    let onReload: () -> Void
    
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
                DonationListItemView(donation: donation)
            }
        }
    }
}

