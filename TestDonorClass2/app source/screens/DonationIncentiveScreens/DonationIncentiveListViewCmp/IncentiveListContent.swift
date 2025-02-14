//
// IncentiveListContent.swift
// TestDonorClass2
//

import SwiftUI

struct IncentiveListContent: View {
    let incentives: [DonationIncentive]
    let onRefresh: () async -> Void
    let onDelete: (IndexSet) async -> Void
    
    var body: some View {
        List {
            if incentives.isEmpty {
                EmptyStateView(
                    message: "No donation incentives found",
                    action: {
                        Task {
                            await onRefresh()
                        }
                    },
                    actionTitle: "Refresh"
                )
            } else {
                ForEach(incentives) { incentive in
                    NavigationLink(destination: DonationIncentiveDetailView(incentive: incentive)) {
                        DonationIncentiveRowView(incentive: incentive)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        await onDelete(indexSet)
                    }
                }
            }
        }
        .refreshable {
            await onRefresh()
        }
    }
}

