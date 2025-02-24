import SwiftUI

// This view handles the detail view logic that was previously in DonorListView
struct DonorDetailContainer: View {
    let donorID: Donor.ID?
    let isMaintenanceMode: Bool
    @EnvironmentObject var donorObject: DonorObjectClass
    @EnvironmentObject var donationObject: DonationObjectClass
    
    var body: some View {
        Group {
            if let donorID = donorID,
               let theDonorIdx = donorObject.donors.firstIndex(where: { $0.id == donorID }) {
                if isMaintenanceMode {
                    DonorDetailView(donor: $donorObject.donors[theDonorIdx])
                        .environmentObject(donationObject)
                        .toolbar(.hidden, for: .tabBar)
                } else {
                    DonationEditView(donor: donorObject.donors[theDonorIdx])
                        .environmentObject(donationObject)
                        .toolbar(.hidden, for: .tabBar)
                }
            } else {
                DonorInstructionsView()
                    .padding(32)
                    .toolbar(.visible, for: .tabBar)
            }
        }
    }
}

// End of file. No additional code.
