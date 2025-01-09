    //
    //  CampaignEditView.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz
    //

    import SwiftUI

    // MARK: - Edit Mode Enum
    // Defines whether we're adding a new campaign or editing an existing one
    enum CampaignEditMode {
        case add                // For creating new campaigns
        case edit(Campaign)     // For editing existing campaigns, carries the campaign data
    }

    // MARK: - Campaign Edit View
    struct CampaignEditView: View {
        // Environment properties for view management
        @Environment(\.dismiss) private var dismiss              // Used to dismiss the view
        @EnvironmentObject var campaignObject: CampaignObjectClass  // Campaign data manager
        
        // The mode determines if we're adding or editing a campaign
        let mode: CampaignEditMode
        
        // State variables to hold form input values
        @State private var name = ""               // Campaign name
        @State private var campaignCode = ""       // Unique campaign code
        @State private var description = ""        // Campaign description
        @State private var startDate: Date?       // Campaign start date
        @State private var endDate: Date?         // Campaign end date
        @State private var status = CampaignStatus.draft  // Campaign status
        @State private var goal: Double?          // Campaign fundraising goal
        
        // Alert handling properties
        @State private var showAlert = false      // Controls alert visibility
        @State private var alertMessage = ""      // Alert message content
        
        // Computed property to check if we're in edit mode
        var isEditing: Bool {
            switch mode {
            case .add: return false
            case .edit: return true
            }
        }
        
        var body: some View {
            NavigationView {
                Form {
                    // Basic Information Section
                    Section(header: Text("Basic Information")) {
                        // Text input fields for campaign details
                        TextField("Campaign Name", text: $name)
                        TextField("Campaign Code", text: $campaignCode)
                        // Multi-line text field for description
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    
                    // Campaign Details Section
                    Section(header: Text("Campaign Details")) {
                        // Date pickers with default values if dates are nil
                        DatePicker("Start Date", selection: Binding(
                            get: { startDate ?? Date() },
                            set: { startDate = $0 }
                        ), displayedComponents: [.date])
                        
                        DatePicker("End Date", selection: Binding(
                            get: { endDate ?? Date() },
                            set: { endDate = $0 }
                        ), displayedComponents: [.date])
                        
                        // Status picker showing all possible campaign statuses
                        Picker("Status", selection: $status) {
                            ForEach([CampaignStatus.draft, .active, .completed, .cancelled], id: \.rawValue) { status in
                                Text(status.rawValue.capitalized)
                                    .tag(status)
                            }
                        }
                        
                        // Goal amount input with currency formatting
                        TextField("Goal Amount", value: $goal, format: .currency(code: "USD"))
                    }
                }
                // Navigation title changes based on mode
                .navigationTitle(isEditing ? "Edit Campaign" : "New Campaign")
                .toolbar {
                    // Cancel button in leading position
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    // Save/Add button in trailing position
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(isEditing ? "Save" : "Add") {
                            saveOrUpdateCampaign()
                        }
                    }
                }
                // Error alert configuration
                .alert("Error", isPresented: $showAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(alertMessage)
                }
                // Load existing campaign data when editing
                .onAppear {
                    if case .edit(let campaign) = mode {
                        loadCampaign(campaign)
                    }
                }
            }
        }
        
        // Loads existing campaign data into form fields
        private func loadCampaign(_ campaign: Campaign) {
            name = campaign.name
            campaignCode = campaign.campaignCode
            description = campaign.description ?? ""
            startDate = campaign.startDate
            endDate = campaign.endDate
            status = campaign.status
            goal = campaign.goal
        }
        
        // Handles both saving new campaigns and updating existing ones
        private func saveOrUpdateCampaign() {
            let currentDate = Date()
            var campaign: Campaign
            
            if isEditing {
                // When editing, preserve existing campaign's identity and metadata
                if case .edit(let existingCampaign) = mode {
                    campaign = Campaign(
                        uuid: existingCampaign.uuid,        // Keep original UUID
                        campaignCode: campaignCode,         // Updated code
                        name: name,                        // Updated name
                        description: description,           // Updated description
                        startDate: startDate,              // Updated start date
                        endDate: endDate,                  // Updated end date
                        status: status,                    // Updated status
                        goal: goal,                        // Updated goal
                        createdAt: existingCampaign.createdAt,  // Keep original creation date
                        updatedAt: currentDate             // New update timestamp
                    )
                    campaign.id = existingCampaign.id      // Keep original database ID
                } else {
                    return  // Safety check - shouldn't happen
                }
            } else {
                // Creating a new campaign
    //                let x = 111
                campaign = Campaign(
                    uuid: "",        // Keep original UUID
    //                    uuid: UUID().uuidString,      // Generate new UUID
                    campaignCode: campaignCode,     // New campaign code
                    name: name,                    // New name
                    description: description,       // New description
                    startDate: startDate,          // New start date
                    endDate: endDate,              // New end date
                    status: status,                // Initial status
                    goal: goal,                    // Initial goal
                    createdAt: currentDate,        // Set creation timestamp
                    updatedAt: currentDate         // Set initial update timestamp
                )
            }
            
            // Asynchronously save or update the campaign
            Task {
                do {
                    if isEditing {
                        try await campaignObject.updateCampaign(campaign)
                    } else {
                        try await campaignObject.addCampaign(campaign)
                    }
                    // Dispatch UI updates to the main thread
                    await MainActor.run {
                        dismiss()  // Close the form on success
                    }
                } catch {
                    // Dispatch UI updates to the main thread
                    await MainActor.run {
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                }
            }
        }
        
        // Helper to get campaign ID when editing
        private func getCampaignId() -> Int? {
            if case .edit(let campaign) = mode {
                return campaign.id
            }
            return nil
        }
        
        // Helper to get campaign UUID when editing
        private func getCampaignUUID() -> String {
            if case .edit(let campaign) = mode {
                return campaign.uuid
            }
            return UUID().uuidString
        }
    }

    // MARK: - Preview Provider
    // Provides sample data for SwiftUI preview
    struct CampaignEditView_Previews: PreviewProvider {
        static let sampleCampaign = Campaign(
            campaignCode: "CAM001",
            name: "Annual Fundraiser",
            description: "Our annual fundraising campaign",
            startDate: Date(),
            endDate: Date().addingTimeInterval(30*24*60*60),
            status: .active,
            goal: 50000.0
        )
        
        static var previews: some View {
            Group {
                // Preview for Add mode
                CampaignEditView(mode: .add)
                    .environmentObject(CampaignObjectClass())
                    .previewDisplayName("Add Mode")
                
                // Preview for Edit mode
                CampaignEditView(mode: .edit(sampleCampaign))
                    .environmentObject(CampaignObjectClass())
                    .previewDisplayName("Edit Mode")
            }
        }
    }
