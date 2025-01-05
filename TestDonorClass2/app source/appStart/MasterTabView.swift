    //
    //  File.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 1/4/25.
    //

import SwiftUI
struct MasterTabView: View {
    @EnvironmentObject private var donorObject: DonorObjectClass
    @EnvironmentObject private var donationObject: DonationObjectClass
    @EnvironmentObject private var campaignObject : CampaignObjectClass
    @EnvironmentObject private var incentiveObject : DonationIncentiveObjectClass
    @EnvironmentObject private var defaultDonationSettingsViewModel: DefaultDonationSettingsViewModel

    var body: some View {
        
        TabView {
            NavigationView {
                DonorListView(donorObject: donorObject, maintenanceMode: false)
                    .task {
                        await donorObject.loadDonors()
                    }
            }
            .tabItem {
                Label("Donations", systemImage: "dollarsign")
            }
            .tag(0)
            
                //                    NavigationView {
                //                        DonationListView()
                //                            .task {
                //                                await donationObject.loadDonations()
                //                            }
                //                    }
                //                    .tabItem {
                //                        Label("Donations", systemImage: "dollarsign.circle")
                //                    }
                //
                //                    NavigationView {
                //                        CampaignListView(campaignObject: campaignObject)
                //                            .task {
                //                                await campaignObject.loadCampaigns()
                //                            }
                //                    }
                //                    .tabItem {
                //                        Label("Campaigns", systemImage: "flag")
                //                    }
                //
                //                    NavigationView {
                //                        DonationIncentiveListView(incentiveObject: incentiveObject)
                //                            .task {
                //                                await incentiveObject.loadIncentives()
                //                            }
                //                    }
                //                    .tabItem {
                //                        Label("Incentives", systemImage: "gift")
                //                    }
            NavigationView {
                MaintenanceView(campaignObject: campaignObject, incentiveObject: incentiveObject, donorObject: donorObject, donationObject: donationObject)
            }
            .tabItem {
                Label("Maintenance", systemImage: "square.grid.3x1.folder.badge.plus")
            }
            .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
            
        }
    }
    
}

