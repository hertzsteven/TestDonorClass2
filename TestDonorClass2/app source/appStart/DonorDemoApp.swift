    //
    //  DonorDemoApp.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 1/2/25.
    //

    import SwiftUI

    @main
    struct DonorDemoApp: App {
        // Declare the StateObjects without initial values here
        @StateObject private var donorObject: DonorObjectClass
        @StateObject private var donationObject: DonationObjectClass
        @StateObject private var campaignObject: CampaignObjectClass
        @StateObject private var incentiveObject: DonationIncentiveObjectClass
        // This one likely doesn't depend on the database, so it might be okay as is
        @StateObject private var defaultDonationSettingsViewModel: DefaultDonationSettingsViewModel
        

        init() {
            // Initialize the wrapped values EXPLICITLY within init using try!
            // This acknowledges the potential failure during initialization.
            do {
                // Use try! because failure here implies DB setup failed, which is fatal anyway.
                let donorObjectClass = try DonorObjectClass()
                let donationObjectClass = try DonationObjectClass()
                let campaignObjectClass = try CampaignObjectClass()
                let incentiveObjectClass = try DonationIncentiveObjectClass()
                // Assuming this one doesn't throw
                let defaultsVM = DefaultDonationSettingsViewModel()

                // Assign to the StateObject's wrapped value
                _donorObject = StateObject(wrappedValue: donorObjectClass)
                _donationObject = StateObject(wrappedValue: donationObjectClass)
                _campaignObject = StateObject(wrappedValue: campaignObjectClass)
                _incentiveObject = StateObject(wrappedValue: incentiveObjectClass)
                _defaultDonationSettingsViewModel = StateObject(wrappedValue: defaultsVM)

                print("ObservableObjects initialized successfully.")

            } catch {
                 // This catch block is technically only reachable if you replace try! with try
                 // With try!, an error causes a crash before the catch.
                 fatalError("Failed to initialize ObservableObjects: \(error)")
            }


            // --- Your existing directory printing code ---
            let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            print("Catalyst documents path:", docsURL?.path ?? "nil")

            let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
            print("Catalyst library path:", libraryURL?.path ?? "nil")
            // --- End directory printing code ---

        }
        
        var body: some Scene {
            WindowGroup {
                LaunchScreenManager() 
//                DashboardView()
//                MasterTabView()
                .environmentObject(donorObject)
                .environmentObject(donationObject)
                .environmentObject(campaignObject)
                .environmentObject(incentiveObject)
                .environmentObject(defaultDonationSettingsViewModel)
            }
        }
    }
