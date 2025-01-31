//
//  CampaignPickerView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/30/25.
//

import SwiftUI
    struct CampaignPickerViewx: View {
        @EnvironmentObject var campaignObject: CampaignObjectClass
        @Binding var selectedCampaign: Campaign?
        
        var body: some View {
            Section(header: Text("Campaign")) {
                Picker("Campaign", selection: $selectedCampaign) {
                    Text("None").tag(nil as Campaign?)
                    ForEach(campaignObject.campaigns.filter { $0.id ?? 100 > 99 }) { campaign in
//                    ForEach(campaignObject.campaigns) { campaign in
                        Text(campaign.name).tag(campaign  as Campaign?)
                    }
                }
            }
        }
    }
