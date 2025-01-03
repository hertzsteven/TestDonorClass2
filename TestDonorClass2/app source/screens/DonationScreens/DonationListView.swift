import SwiftUI

// MARK: - DonationListView
struct DonationListView: View {
    // Properties
    @EnvironmentObject var donationObject: DonationObjectClass
    
    var body: some View {
        Group {
            switch donationObject.loadingState {
            case .notLoaded, .loading:
                ProgressView("Loading donations...")
            case .loaded:
                if donationObject.donations.isEmpty {
                    ContentUnavailableView("No Donations", 
                        systemImage: "dollarsign.circle",
                        description: Text("There are no donations to display"))
                } else {
                    List(donationObject.donations, id: \.id) { donation in
                        NavigationLink(destination: DonationDetailView(donation: donation)) {
                            DonationRowView(donation: donation)
                        }
                    }
                }
            case .error(let message):
                ContentUnavailableView("Error", 
                    systemImage: "exclamationmark.triangle",
                    description: Text(message))
            }
        }
        .navigationTitle("Donations")
        .task {
            await donationObject.loadDonations()
        }
    }
}

// MARK: - DonationRowView
struct DonationRowView: View {
    let donation: Donation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("$\(String(format: "%.2f", donation.amount))")
                    .font(.headline)
                Spacer()
                Text(donation.paymentStatus.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(paymentStatusColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            
            Text(donation.donationDate, style: .date)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(donation.donationType.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    // Computed properties
    private var paymentStatusColor: Color {
        switch donation.paymentStatus {
        case .completed:
            return .green
        case .pending:
            return .orange
        case .failed:
            return .red
        }
    }
}

// MARK: - Preview Provider
struct DonationListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DonationListView()
                .environmentObject(DonationObjectClass())
        }
    }
}

// End of file
