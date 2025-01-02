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
        
        // Add initializer
        init() {
            _donorObject = StateObject(wrappedValue: DonorObjectClass())
        }
        
        var body: some Scene {
            WindowGroup {
                NavigationView {
                    DonorListView(donorObject: donorObject)
                        .task {
                            await donorObject.loadDonors()
                        }
                }
                .environmentObject(donorObject)
            }
        }
    }
