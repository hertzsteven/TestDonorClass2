    //
    //  File.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 1/4/25.
    //

import SwiftUI
struct MasterTabView: View {
        //    init() {
        //        Thread.sleep(forTimeInterval: 20.0)
        //    }
    
    @EnvironmentObject private var donorObject: DonorObjectClass
    @EnvironmentObject private var donationObject: DonationObjectClass
    @EnvironmentObject private var campaignObject : CampaignObjectClass
    @EnvironmentObject private var incentiveObject : DonationIncentiveObjectClass
    @EnvironmentObject private var defaultDonationSettingsViewModel: DefaultDonationSettingsViewModel
    
    var body: some View {
        
        TabView {
            
                //            NavigationView {
            DonorListView(donorObject: donorObject, maintenanceMode: false)
                //                    .task {
                //                        await donorObject.loadDonors()
                //                    }
            
                //            }
                .tabItem {
                    Label("Donations", systemImage: "dollarsign")
                }
                .tag(0)
            NavigationView {
                MaintenanceView(campaignObject: campaignObject,
                                incentiveObject: incentiveObject,
                                donorObject: donorObject,
                                donationObject: donationObject)
            }
            .tabItem {
                Label("Maintenance", systemImage: "square.grid.3x1.folder.badge.plus")
            }
            .tag(1)

                //            StubPersonView()
                //                .tabItem {
                //                    Label("Stub Person", systemImage: "person")
                //                }
                //                .tag(2)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
            CSVHandlerView()
                .tabItem {
                    Label("Load Data", systemImage: "pencil")
                }
                .tag(3)
        }
    }
    
}

#Preview {
    MasterTabView()
}
