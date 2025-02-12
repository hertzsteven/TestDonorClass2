//
// DonationIncentiveDetailView.swift
// TestDonorClass2
//

import SwiftUI

struct DonationIncentiveDetailView: View {
    @EnvironmentObject var incentiveObject: DonationIncentiveObjectClass
    @State private var showingEditSheet = false
    let incentive: DonationIncentive
    
    var body: some View {
        List {
            Section(header: Text("Incentive Information")) {
                DetailRow(title: "Amount", value: String(format: "$%.2f", incentive.dollarAmount))
                DetailRow(title: "Status", value: incentive.status.rawValue.capitalized)
            }
            
            if let description = incentive.description, !description.isEmpty {
                Section(header: Text("Description")) {
                    Text(description)
                        .font(.body)
                }
            }
            
            Section(header: Text("System Information")) {
                DetailRow(title: "Created", value: incentive.createdAt.formatted())
                DetailRow(title: "Last Updated", value: incentive.updatedAt.formatted())
            }
        }
        .navigationTitle(incentive.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showingEditSheet) {
            DonationIncentiveEditView(mode: .edit(incentive))
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleIncentive = DonationIncentive(
        name: "Early Bird Special",
        description: "Special discount for early donors",
        dollarAmount: 100.00,
        status: .active
    )
    
    return NavigationView {
        DonationIncentiveDetailView(incentive: sampleIncentive)
            .environmentObject(DonationIncentiveObjectClass())
    }
}

