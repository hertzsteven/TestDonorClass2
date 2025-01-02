//
//  DonorDemoApp.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/2/25.
//


import SwiftUI

@main
struct DonorDemoApp: App {
    @StateObject var donorObject = DonorObjectClass()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                DonorListView(donorObject: donorObject)
                    .environmentObject(donorObject)
                    .task {
                        await donorObject.loadDonors()
                    }
            }
        }
    }
}
