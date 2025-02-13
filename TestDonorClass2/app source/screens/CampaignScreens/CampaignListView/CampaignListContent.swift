import SwiftUI

struct CampaignListContent: View {
    let campaigns: [Campaign]
    let onRefresh: () async -> Void
    let onDelete: (IndexSet) async -> Void
    
    var body: some View {
        List {
            if campaigns.isEmpty {
                EmptyStateView(
                    message: "No campaigns found",
                    action: { Task { await onRefresh() } },
                    actionTitle: "Refresh"
                )
            } else {
                ForEach(campaigns) { campaign in
                    NavigationLink(destination: CampaignDetailView(campaign: campaign)) {
                        CampaignRowView(campaign: campaign)
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

