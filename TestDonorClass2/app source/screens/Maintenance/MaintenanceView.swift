//
//  MaintenanceView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/4/25.
//


//
//  MainTabView.swift
//  Donor Organization
//
//  Created by Steven Hertz on 11/30/24.
//

import SwiftUI

// Maintenance View with grid layout
struct MaintenanceView: View {
    @StateObject var campaignObject: CampaignObjectClass
    @StateObject var incentiveObject: DonationIncentiveObjectClass
    @StateObject var donorObject: DonorObjectClass
    @StateObject var donationObject: DonationObjectClass

    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
//        NavigationStack {
            List {
                Section("Donor Management") {
                 NavigationLink("Donors") {
                     DonorListView(donorObject: donorObject, maintenanceMode: true)
                         .task {
                             await donorObject.loadDonors()
                         }
                    }
                }
                
                Section("Donation Management") {
                 NavigationLink("Donations") {
                     DonationListView()
                         .task {
                             await donationObject.loadDonations()
                         }                    }
                }
                
                Section("Incentive Management") {
                 NavigationLink("Incentives") {
                     DonationIncentiveListView(incentiveObject: incentiveObject)
                         .task {
                             await incentiveObject.loadIncentives()
                         }
                    }
                }
                
                Section("Campaign Management") {                    
                    NavigationLink("Campaigns") {
                        CampaignListView(campaignObject: campaignObject)
                            .task {
                                await campaignObject.loadCampaigns()
                            }

                    }
                }
            }
            .navigationTitle("Maintenance")
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
//        }
    }
}

#Preview {
    MaintenanceView(campaignObject: CampaignObjectClass(), incentiveObject: DonationIncentiveObjectClass(), donorObject: DonorObjectClass(), donationObject: DonationObjectClass())
}


