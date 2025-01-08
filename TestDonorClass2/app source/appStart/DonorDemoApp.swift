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
        @StateObject private var defaultDonationSettingsViewModel = DefaultDonationSettingsViewModel()

        
        // Add initializer
        init() {
//            Thread.sleep(forTimeInterval: 15.0)
            _donorObject = StateObject(wrappedValue: DonorObjectClass())
            _donationObject = StateObject(wrappedValue: DonationObjectClass())
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
