//
// IncentiveListContent.swift
// TestDonorClass2
//

import SwiftUI

struct IncentiveListContent: View {
    let incentives: [DonationIncentive]
    let onRefresh: () async -> Void
    let onDelete: (IndexSet) async -> Void
    @Binding var returnedFromDetail: Bool
    
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
                    NavigationLink(
                        destination: DonationIncentiveDetailView(incentive: incentive)
                            .onAppear {returnedFromDetail = true},
//                            .onDisappear {
//                                returnedFromDetail = true
//                            },
                        label: {
                            DonationIncentiveRowView(incentive: incentive)
                        }
                    )
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
