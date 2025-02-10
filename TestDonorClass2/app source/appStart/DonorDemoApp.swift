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
        
        @StateObject private var campaignObject                     = CampaignObjectClass()
        @StateObject private var incentiveObject                    = DonationIncentiveObjectClass()
        @StateObject private var defaultDonationSettingsViewModel   = DefaultDonationSettingsViewModel()

        

        init() {
            _donorObject    =  StateObject(wrappedValue: DonorObjectClass())
            _donationObject =  StateObject(wrappedValue: DonationObjectClass())

            
            let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            print("Catalyst documents path:", docsURL?.path ?? "nil")

            let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
            print("Catalyst library path:", libraryURL?.path ?? "nil")

        }
        
        var body: some Scene {
            WindowGroup {
                MasterTabView()
                .environmentObject(donorObject)
                .environmentObject(donationObject)
                .environmentObject(campaignObject)
                .environmentObject(incentiveObject)
                .environmentObject(defaultDonationSettingsViewModel)
            }
        }
    }
