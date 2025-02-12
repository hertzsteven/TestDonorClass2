//  SettingsView.swift
//  Donor Organization
//
//  Created by Steven Hertz on 12/5/24.
//


import SwiftUI

struct SettingsView: View {
        // App Settings
        //    @AppStorage("defaultDonationType") private var defaultDonationType = TypeOfDonation.cash
        //    @AppStorage("autoEmailReceipts") private var autoEmailReceipts = false
        //    @AppStorage("defaultEmailTemplate") private var defaultEmailTemplate = "standard"
        //    @AppStorage("showDonationPreview") private var showDonationPreview = true
    
        // User Preferences
    @AppStorage("organizationName") private var organizationName = ""
    @AppStorage("organizationEmail") private var organizationEmail = ""
        @AppStorage("addressLine1") private var addressLine1 = ""
        @AppStorage("city") private var city = ""
        @AppStorage("state") private var state = ""
        @AppStorage("zip") private var zip = ""
        @AppStorage("ein") private var ein = ""
        @AppStorage("website") private var website = ""
        @AppStorage("phone") private var phone = ""
    
    var body: some View {
        NavigationStack {
            Form {
                    //                Section("Donation Defaults") {
                    //                    Picker("Default Donation Type", selection: $defaultDonationType) {
                    //                        ForEach(TypeOfDonation.allCases, id: \.self) { type in
                    //                            Text(type.rawValue.capitalized)
                    //                                .tag(type)
                    //                        }
                    //                    }
                    //
                    //                    Toggle("Auto-generate Email Receipts", isOn: $autoEmailReceipts)
                    //
                    //                    Picker("Default Email Template", selection: $defaultEmailTemplate) {
                    //                        Text("Standard").tag("standard")
                    //                        Text("Detailed").tag("detailed")
                    //                        Text("Simple").tag("simple")
                    //                    }
                    //
                    //                    Toggle("Show Donation Preview", isOn: $showDonationPreview)
                    //                }
                
                Section("Organization Information") {
                    TextField("Organization Name", text: $organizationName)
                    TextField("Address", text: $addressLine1)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP Code", text: $zip)
                    TextField("EIN", text: $ein)
                    TextField("Website", text: $website)
                    TextField("Email", text: $organizationEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Database") {
                    Button("Verify Database") {
                        verifyDatabase()
                    }
                    NavigationLink(destination: BackupDatabaseView()) {
                        Text("Backup Data")
                            .foregroundColor(.blue) // Makes text blue
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func verifyDatabase() {
        do {
            try DatabaseManager.shared.testDatabaseConnection()
                // Show success message
        } catch {
                // Show error message
        }
    }
    
    private func exportData() {
        NavigationLink(destination: BackupDatabaseView()) {
            Text("Backup Data")
        }
    }
}
    
        //// Update MainTabView to include Settings
        //struct MainTabView: View {
//    var body: some View {
//        TabView {
//            NavigationStack {
//                ChooseADonorView()
//            }
//            .tabItem {
//                Label("Donations", systemImage: "dollarsign.circle")
//            }
//            
//            SettingsView()
//                .tabItem {
//                    Label("Settings", systemImage: "gear")
//                }
//        }
//    }
//}

#Preview {
    SettingsView()
}
