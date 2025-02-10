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

            DonorListView(donorObject: donorObject, maintenanceMode: false)
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
            

            NavigationView {
                BatchDonationView()
            }
            .navigationViewStyle(.stack)  // forces single-column layout on iPad
            .tabItem {
                Label("Batch Donations", systemImage: "tablecells.badge.ellipsis")
            }
                //                .tag(2)
            
            
            NavigationStack {
                DonorSearchView()
            }
            .tabItem {
                Label("Donors", systemImage: "person.3")
            }
            .tag(4)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
            
                // New Tab for DonationEditView
            DonationEditView(donor: Donor(
                firstName: "John",
                lastName: "Doe"
            ))
            .environmentObject(DonorObjectClass())
            .environmentObject(CampaignObjectClass())
            .environmentObject(DonationIncentiveObjectClass())
            .environmentObject(DefaultDonationSettingsViewModel())
            .environmentObject(DonationObjectClass())
            .tabItem {
                Label("Edit Donation", systemImage: "square.and.pencil")
            }
            .tag(4)
            


                //            CSVHandlerView()
                //                .tabItem {
                //                    Label("Load Data", systemImage: "pencil")
                //                }
                //                .tag(4)
        }
    }
    
}

#Preview {
    MasterTabView()
}
