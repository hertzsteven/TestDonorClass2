//
//  CampaignDetailView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz
//

import SwiftUI

struct CampaignDetailView: View {
    @EnvironmentObject var campaignObject: CampaignObjectClass
    @State private var showingEditSheet = false
    let campaign: Campaign
    
    var body: some View {
        List {
            Section(header: Text("Campaign Information")) {
                DetailRow(title: "Campaign Code", value: campaign.campaignCode)
                DetailRow(title: "Status", value: campaign.status.rawValue.capitalized)
                if let goal = campaign.goal {
                    DetailRow(title: "Goal", value: String(format: "$%.2f", goal))
                }
            }
            
            Section(header: Text("Dates")) {
                if let startDate = campaign.startDate {
                    DetailRow(title: "Start Date", value: startDate.formatted(date: .long, time: .omitted))
                }
                if let endDate = campaign.endDate {
                    DetailRow(title: "End Date", value: endDate.formatted(date: .long, time: .omitted))
                }
            }
            
            if let description = campaign.description, !description.isEmpty {
                Section(header: Text("Description")) {
                    Text(description)
                        .font(.body)
                }
            }
        }
        .navigationTitle(campaign.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            CampaignEditView(mode: .edit(campaign))
        }
    }
}

// MARK: - Supporting Views
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
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
    
    return NavigationView {
        CampaignDetailView(campaign: sampleCampaign)
            .environmentObject(CampaignObjectClass())
    }
}

