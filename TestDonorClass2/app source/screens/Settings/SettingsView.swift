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
    @State private var receiptOutputModeSelection: ReceiptOutputMode
    @State private var showReceiptPreviewSheet = false
    @State private var receiptPreviewData: Data?
    @State private var showReceiptPreviewError = false
    @State private var receiptPreviewErrorMessage = ""
    @State private var letterGreetingDraft: String
    @State private var letterBodyDraft: String

    @AppStorage("maxReceiptsPerPrint") private var maxReceiptsPerPrint: Int = 10

    init(organizationManager: OrganizationSettingsManager) {
        self.organizationManager = organizationManager
        _tempSettings = State(initialValue: TempOrgSettings(from: organizationManager.organizationInfo))
        _receiptOutputModeSelection = State(initialValue: organizationManager.receiptOutputMode)
        _letterGreetingDraft = State(initialValue: organizationManager.receiptLetterGreeting)
        _letterBodyDraft = State(initialValue: organizationManager.receiptLetterBody)
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
                    Button("Delete All Donations After 2000 Before September 25th", role: .destructive) {
                        deleteRecentDonations()
                    }
                    Button("Verify Database") {
                        verifyDatabase()
                    }

                    NavigationLink(destination: BackupDatabaseView()) {
                        Text("Backup & Restore")
                            .foregroundColor(.blue)
                    }
                }
                
                Section("Receipt Printing") {
                    Picker("Receipt output", selection: $receiptOutputModeSelection) {
                        ForEach(ReceiptOutputMode.allCases) { mode in
                            Text(mode.pickerTitle).tag(mode)
                        }
                    }
                    .onChange(of: receiptOutputModeSelection) { _, newValue in
                        organizationManager.receiptOutputMode = newValue
                    }

                    HStack {
                        Text("Max receipts per print:")
                            .font(.subheadline)
                        Spacer()
                        Text("\(maxReceiptsPerPrint)")
                            .font(.subheadline)
                            .bold()
                            .frame(minWidth: 30)
                        Stepper("", value: $maxReceiptsPerPrint, in: 1...100)
                            .labelsHidden()
                            .fixedSize()
                    }

                    Button("Preview test receipt PDF", systemImage: "doc.richtext") {
                        generateReceiptPreview()
                    }

                    Button(action: {
                        printTestReceipt()
                    }) {
                        HStack {
                            Label("Print Test Receipt", systemImage: "checkmark.circle")
                            Spacer()
                        }
                    }
                    .foregroundStyle(.orange)
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Greeting")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $letterGreetingDraft)
                            .frame(minHeight: 44)
                            .onChange(of: letterGreetingDraft) { _, newValue in
                                organizationManager.receiptLetterGreeting = newValue
                            }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Body")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $letterBodyDraft)
                            .frame(minHeight: 160)
                            .onChange(of: letterBodyDraft) { _, newValue in
                                organizationManager.receiptLetterBody = newValue
                            }
                    }

                    Button("Reset to default", systemImage: "arrow.uturn.backward") {
                        organizationManager.resetReceiptLetterToDefault()
                        letterGreetingDraft = organizationManager.receiptLetterGreeting
                        letterBodyDraft = organizationManager.receiptLetterBody
                    }
                } header: {
                    Text("Receipt Letter")
                } footer: {
                    Text("Used for Template and Pre-printed receipt modes. Placeholders: {donorName}, {amount}, {date}.")
                }

                Section("Receipt Template") {
                    NavigationLink(destination: ReceiptTemplateView()) {
                        Label("Receipt PDF Template", systemImage: "doc.text.fill")
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
            .sheet(isPresented: $showReceiptPreviewSheet) {
                NavigationStack {
                    Group {
                        if let data = receiptPreviewData {
                            PDFKitView(data: data)
                        } else {
                            ContentUnavailableView("No PDF", systemImage: "doc")
                        }
                    }
                    .navigationTitle("Receipt preview")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showReceiptPreviewSheet = false
                            }
                        }
                    }
                }
            }
            .alert("Preview failed", isPresented: $showReceiptPreviewError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(receiptPreviewErrorMessage)
            }
            .onAppear {
                receiptOutputModeSelection = organizationManager.receiptOutputMode
                letterGreetingDraft = organizationManager.receiptLetterGreeting
                letterBodyDraft = organizationManager.receiptLetterBody
            }
        }
    }

    private func generateReceiptPreview() {
        let donation = createTestDonationInfo()
        do {
            let data = try ReceiptPrintingService().pdfData(
                for: donation,
                mode: receiptOutputModeSelection
            )
            receiptPreviewData = data
            showReceiptPreviewSheet = true
        } catch {
            receiptPreviewErrorMessage = error.localizedDescription
            showReceiptPreviewError = true
        }
    }
    
    private func verifyDatabase() {
        do {
            try DatabaseManager.shared.testDatabaseConnection()
        } catch {
            // Show error message
        }
    }
    
    private func deleteRecentDonations() {
        do {
            let dbPool = try DatabaseManager.shared.getDbPool()
            try dbPool.write { db in
                try db.execute(sql: "DELETE FROM donation WHERE donation_date > '2000-01-01 00:00:00' AND donation_date < '2025-09-10 00:00:00' ")
            }
            // Optionally show success message or refresh UI
        } catch {
            // Handle error - you might want to show an alert here
            print("Failed to delete donations: \(error)")
        }
    }
    
    private func createTestDonationInfo() -> DonationInfo {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: Date())
        
        return DonationInfo(
            donorName: "John Doe",
            donorTitle: "Mr.",
            donationAmount: 100.00,
            date: dateString,
            donorAddress: "123 Main Street",
            donorCity: "New York",
            donorState: "NY",
            donorZip: "10001",
            receiptNumber: "TEST-001"
        )
    }
    
    private func printTestReceipt() {
        let testDonation = createTestDonationInfo()
        let printingService = ReceiptPrintingService()

        printingService.printReceipt(for: testDonation, mode: receiptOutputModeSelection) { success in
            // Test print doesn't need alert in Settings - just prints
            print("Test receipt print \(success ? "succeeded" : "failed or cancelled")")
        }
    }
}

#Preview {
    SettingsView(organizationManager: OrganizationSettingsManager())
}
