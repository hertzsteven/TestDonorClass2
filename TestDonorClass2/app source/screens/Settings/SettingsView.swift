//  SettingsView.swift
//  Donor Organization
//
//  Created by Steven Hertz on 12/5/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var organizationManager: OrganizationSettingsManager
    
    @State private var tempSettings: TempOrgSettings
    @State private var showingSaveAlert = false
    @State private var hasUnsavedChanges = false
    
    init(organizationManager: OrganizationSettingsManager) {
        self.organizationManager = organizationManager
        _tempSettings = State(initialValue: TempOrgSettings(from: organizationManager.organizationInfo))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Organization Name", text: $tempSettings.name)
                        .onChange(of: tempSettings.name) { hasUnsavedChanges = true }
                    TextField("EIN", text: $tempSettings.ein)
                        .onChange(of: tempSettings.ein) { hasUnsavedChanges = true }
                }
                
                Section("Contact Information") {
                    TextField("Email", text: $tempSettings.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .onChange(of: tempSettings.email) { hasUnsavedChanges = true }
                    TextField("Phone", text: $tempSettings.phone)
                        .keyboardType(.phonePad)
                        .onChange(of: tempSettings.phone) { hasUnsavedChanges = true }
                    TextField("Website", text: $tempSettings.website)
                        .onChange(of: tempSettings.website) { hasUnsavedChanges = true }
                }
                
                Section("Address Information") {
                    TextField("Street Address", text: $tempSettings.addressLine1)
                        .onChange(of: tempSettings.addressLine1) { hasUnsavedChanges = true }
                    TextField("City", text: $tempSettings.city)
                        .onChange(of: tempSettings.city) { hasUnsavedChanges = true }
                    TextField("State", text: $tempSettings.state)
                        .onChange(of: tempSettings.state) { hasUnsavedChanges = true }
                    TextField("ZIP Code", text: $tempSettings.zip)
                        .onChange(of: tempSettings.zip) { hasUnsavedChanges = true }
                }
                
                Section("Database") {
                    Button("Verify Database") {
                        verifyDatabase()
                    }
                    NavigationLink(destination: BackupDatabaseView()) {
                        Text("Backup Data")
                            .foregroundColor(.blue)
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showingSaveAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        organizationManager.saveOrganizationInfo(tempSettings.toOrgInfo())
                        hasUnsavedChanges = false
                        dismiss()
                    }
                    .disabled(!hasUnsavedChanges)
                }
            }
            .alert("Unsaved Changes", isPresented: $showingSaveAlert) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to dismiss without saving?")
            }
        }
    }
    
    private func verifyDatabase() {
        do {
            try DatabaseManager.shared.testDatabaseConnection()
        } catch {
            // Show error message
        }
    }
}

#Preview {
    SettingsView(organizationManager: OrganizationSettingsManager())
}
