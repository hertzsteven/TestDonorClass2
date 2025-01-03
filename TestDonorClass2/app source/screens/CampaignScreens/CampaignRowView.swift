//
//  CampaignRowView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz
//

import SwiftUI

struct CampaignRowView: View {
    let campaign: Campaign
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(campaign.name)
                .font(.headline)
            
            HStack {
                Text(campaign.campaignCode)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(campaign.status.rawValue.capitalized)
                    .font(.caption)
                    .padding(4)
                    .background(
                        campaign.status == .active ? Color.green.opacity(0.2) :
                            campaign.status == .completed ? Color.blue.opacity(0.2) :
                            campaign.status == .draft ? Color.orange.opacity(0.2) :
                            Color.red.opacity(0.2)
                    )
                    .cornerRadius(4)
            }
            
            if let goal = campaign.goal {
                Text("Goal: $\(String(format: "%.2f", goal))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    let sampleCampaign = Campaign(
        campaignCode: "CAM001",
        name: "Annual Fundraiser",
        description: "Our annual fundraising campaign",
        startDate: Date(),
        endDate: Date().addingTimeInterval(30*24*60*60),
        status: .active,
        goal: 50000.0
    )
    
    return CampaignRowView(campaign: sampleCampaign)
        .previewLayout(.sizeThatFits)
        .padding()
}

