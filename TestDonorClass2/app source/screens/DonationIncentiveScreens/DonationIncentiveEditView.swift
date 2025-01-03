//
// DonationIncentiveEditView.swift
// TestDonorClass2
//

import SwiftUI

// MARK: - Edit Mode Enum
enum DonationIncentiveEditMode {
    case add
    case edit(DonationIncentive)
}

// MARK: - Donation Incentive Edit View
struct DonationIncentiveEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var incentiveObject: DonationIncentiveObjectClass
    
    let mode: DonationIncentiveEditMode
    
    @State private var name = ""
    @State private var description = ""
    @State private var dollarAmount: Double = 0.0
    @State private var status = DonationIncentiveStatus.active
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var isEditing: Bool {
        switch mode {
        case .add: return false
        case .edit: return true
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Incentive Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Incentive Details")) {
                    TextField("Amount", value: $dollarAmount, format: .currency(code: "USD"))
                    
                    Picker("Status", selection: $status) {
                        ForEach([DonationIncentiveStatus.active,
                                .inactive,
                                .archived], id: \.rawValue) { status in
                            Text(status.rawValue.capitalized)
                                .tag(status)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Incentive" : "New Incentive")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Add") {
                        saveOrUpdateIncentive()
                    }
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                if case .edit(let incentive) = mode {
                    loadIncentive(incentive)
                }
            }
        }
    }
    
    private func loadIncentive(_ incentive: DonationIncentive) {
        name = incentive.name
        description = incentive.description ?? ""
        dollarAmount = incentive.dollarAmount
        status = incentive.status
    }
    
    private func saveOrUpdateIncentive() {
        let currentDate = Date()
        var incentive: DonationIncentive
        
        if isEditing {
            if case .edit(let existingIncentive) = mode {
                incentive = DonationIncentive(
                    uuid: existingIncentive.uuid,
                    name: name,
                    description: description,
                    dollarAmount: dollarAmount,
                    status: status,
                    createdAt: existingIncentive.createdAt,
                    updatedAt: currentDate
                )
                incentive.id = existingIncentive.id
            } else {
                return
            }
        } else {
            incentive = DonationIncentive(
                uuid: UUID().uuidString,
                name: name,
                description: description,
                dollarAmount: dollarAmount,
                status: status,
                createdAt: currentDate,
                updatedAt: currentDate
            )
        }
        
        Task {
            do {
                try await incentive.validate()
                if isEditing {
                    try await incentiveObject.updateIncentive(incentive)
                } else {
                    try await incentiveObject.addIncentive(incentive)
                }
                dismiss()
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleIncentive = DonationIncentive(
        name: "Early Bird Special",
        description: "Special discount for early donors",
        dollarAmount: 100.00,
        status: .active
    )
    
    return Group {
        DonationIncentiveEditView(mode: .add)
            .environmentObject(DonationIncentiveObjectClass())
            .previewDisplayName("Add Mode")
        
        DonationIncentiveEditView(mode: .edit(sampleIncentive))
            .environmentObject(DonationIncentiveObjectClass())
            .previewDisplayName("Edit Mode")
    }
}

