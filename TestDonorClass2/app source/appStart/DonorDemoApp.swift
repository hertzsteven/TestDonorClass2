    //
    //  DonorDemoApp.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 1/2/25.
    //


import SwiftUI

@main
struct DonorDemoApp: App {
    
    @State private var databaseURL: URL?
    @State private var errorMessage: String?
    
    init() {
        setupDatabase()
    }

  /// Scan for .sqlite files in Documents
//  private let dbURLs: [URL] = {
//    let docs = FileManager.default
//      .urls(for: .documentDirectory, in: .userDomainMask)
//      .first!
//    return (try? FileManager.default
//      .contentsOfDirectory(at: docs,
//                           includingPropertiesForKeys: nil))
//      ?.filter { $0.pathExtension.lowercased() == "sqlite" } ?? []
//  }()

  var body: some Scene {
    WindowGroup {
      DatabaseSelectorView()
    }
  }
    
    func setupDatabase() {
        let fileManager = FileManager.default
        
        do {
            /* example with all the parameters filled in
            
             let dbURL = try fileManager.sqliteDatabaseURL(
                databaseName: "donations_co",
                fileExtension: "sqlite",
                subdirectory: "Databases1",
                copyFromBundleIfNeeded: true
            )
            */
            
             let dbURLCO = try fileManager.copySqliteDatabasesFromResourcesToAppSupp(
                databaseName: "donations_co",
                forceCopy: false
            )
            self.databaseURL = dbURLCO
            print("Database CO is ready at: \(dbURLCO.path)")
            
            let dbURLUTI = try fileManager.copySqliteDatabasesFromResourcesToAppSupp(
                databaseName: "donations_uti",
                forceCopy: false
            )
            self.databaseURL = dbURLUTI
            print("Database UTI is ready at: \(dbURLUTI.path)")
            

            // Just file names (default)
            FileManager.default.printFilesInAppSupportDirectory()

            // Full paths
            FileManager.default.printFilesInAppSupportDirectory(displayStyle: .fullPath)

//            fileManager.printFilesInAppSupportDirectory()
            
            print("finished setting up database")
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error setting up database: \(error.localizedDescription)")
        }
    }
}

//    import SwiftUI
//
//    @main
//    struct DonorDemoApp: App {
//        // Declare the StateObjects without initial values here
//        @StateObject private var donorObject: DonorObjectClass
//        @StateObject private var donationObject: DonationObjectClass
//        @StateObject private var campaignObject: CampaignObjectClass
//        @StateObject private var incentiveObject: DonationIncentiveObjectClass
//        // This one likely doesn't depend on the database, so it might be okay as is
//        @StateObject private var defaultDonationSettingsViewModel: DefaultDonationSettingsViewModel
//        
//
//        init() {
//            // Initialize the wrapped values EXPLICITLY within init using try!
//            // This acknowledges the potential failure during initialization.
//            do {
//                // Use try! because failure here implies DB setup failed, which is fatal anyway.
//                let donorObjectClass = try DonorObjectClass()
//                let donationObjectClass = try DonationObjectClass()
//                let campaignObjectClass = try CampaignObjectClass()
//                let incentiveObjectClass = try DonationIncentiveObjectClass()
//                // Assuming this one doesn't throw
//                let defaultsVM = DefaultDonationSettingsViewModel()
//
//                // Assign to the StateObject's wrapped value
//                _donorObject = StateObject(wrappedValue: donorObjectClass)
//                _donationObject = StateObject(wrappedValue: donationObjectClass)
//                _campaignObject = StateObject(wrappedValue: campaignObjectClass)
//                _incentiveObject = StateObject(wrappedValue: incentiveObjectClass)
//                _defaultDonationSettingsViewModel = StateObject(wrappedValue: defaultsVM)
//
//                print("ObservableObjects initialized successfully.")
//
//            } catch {
//                 // This catch block is technically only reachable if you replace try! with try
//                 // With try!, an error causes a crash before the catch.
//                 fatalError("Failed to initialize ObservableObjects: \(error)")
//            }
//
//
//            // --- Your existing directory printing code ---
//            let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
//            print("Catalyst documents path:", docsURL?.path ?? "nil")
//
//            let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
//            print("Catalyst library path:", libraryURL?.path ?? "nil")
//            // --- End directory printing code ---
//
//        }
//        
//        var body: some Scene {
//            WindowGroup {
//                LaunchScreenManager() 
////                DashboardView()
////                MasterTabView()
//                .environmentObject(donorObject)
//                .environmentObject(donationObject)
//                .environmentObject(campaignObject)
//                .environmentObject(incentiveObject)
//                .environmentObject(defaultDonationSettingsViewModel)
//            }
//        }
//    }
