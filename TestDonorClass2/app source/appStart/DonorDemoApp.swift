    //
    //  DonorDemoApp.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 1/2/25.
    //

    import SwiftUI

    @main
    struct DonorDemoApp: App {
        // Replace direct initialization with @StateObject property wrapper
        @StateObject private var donorObject: DonorObjectClass
        @StateObject private var donationObject: DonationObjectClass
        @StateObject private var campaignObject = CampaignObjectClass()
        @StateObject private var incentiveObject = DonationIncentiveObjectClass()
        
        // Add initializer
        init() {
            _donorObject = StateObject(wrappedValue: DonorObjectClass())
            _donationObject = StateObject(wrappedValue: DonationObjectClass())
        }
        
        var body: some Scene {
            WindowGroup {
                TabView {
                    NavigationView {
                        DonorListView(donorObject: donorObject)
                            .task {
                                await donorObject.loadDonors()
                            }
                    }
                    .tabItem {
                        Label("Donors", systemImage: "person.3")
                    }
                    
                    NavigationView {
                        DonationListView()
                            .task {
                                await donationObject.loadDonations()
                            }
                    }
                    .tabItem {
                        Label("Donations", systemImage: "dollarsign.circle")
                    }
                    
                    NavigationView {
                        CampaignListView(campaignObject: campaignObject)
                            .task {
                                await campaignObject.loadCampaigns()
                            }
                    }
                    .tabItem {
                        Label("Campaigns", systemImage: "flag")
                    }
                    
                    NavigationView {
                        DonationIncentiveListView(incentiveObject: incentiveObject)
                            .task {
                                await incentiveObject.loadIncentives()
                            }
                    }
                    .tabItem {
                        Label("Incentives", systemImage: "gift")
                    }
                }
                .environmentObject(donorObject)
                .environmentObject(donationObject)
                .environmentObject(campaignObject)
                .environmentObject(incentiveObject)
            }
        }
    }
