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
                        CampaignListView(campaignObject: campaignObject)
                            .task {
                                await campaignObject.loadCampaigns()
                            }
                    }
                    .tabItem {
                        Label("Campaigns", systemImage: "flag")
                    }
                }
                .environmentObject(donorObject)
                .environmentObject(donationObject)
                .environmentObject(campaignObject)
            }
        }
    }
