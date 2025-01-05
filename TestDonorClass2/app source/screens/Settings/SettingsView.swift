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
    @AppStorage("taxId") private var taxId = ""
    
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
                        TextField("Organization Email", text: $organizationEmail)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        TextField("Tax ID", text: $taxId)
                    }
                    
                    Section("Database") {
                        Button("Verify Database") {
                            verifyDatabase()
                        }
                        
                        Button("Export Data") {
                            exportData()
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
                // Implement data export functionality
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
