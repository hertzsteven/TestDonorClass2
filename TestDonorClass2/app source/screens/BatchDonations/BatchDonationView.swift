//
//  BatchDonationView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/30/25.
//


import SwiftUI

struct BatchDonationView: View {
    @EnvironmentObject private var donorObject: DonorObjectClass
    @EnvironmentObject private var donationObject: DonationObjectClass
    
    @StateObject private var viewModel = BatchDonationViewModel()


    // If you want your focus to jump from row to row:
    @FocusState private var focusedRowID: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Global donation amount across all rows
            HStack {
                Text("Global Amount:")
                TextField("Enter global donation",
                          text: $viewModel.globalDonation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 100)
            }
            .padding(.top)
            
            // Optional column headers
            HStack {
                Text("Code")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Donor Information")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Donation")
                    .frame(width: 80, alignment: .leading)
                Text("Find")
                    .frame(width: 50, alignment: .center)
            }
            .font(.headline)
            .padding(.horizontal)

            // The list of rows
            List {
                ForEach($viewModel.rows) { $row in
                    HStack {
                        // Donor Code (ID) text field
                        TextField("Donor ID", value: $row.donorID, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                            .focused($focusedRowID, equals: row.id)

                        // Donor Information text
                        Text(row.displayInfo)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(row.isValidDonor ? .primary : .red)

                        // Donation text field
                        TextField("Amount", text: $row.donationOverride)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .disabled(!row.isValidDonor)

                        // Find button
                        Button {
                            Task {
                                await viewModel.findDonor(for: row.id)
                                // Move focus to the row ID we just appended
                                focusedRowID = viewModel.focusedRowID
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        .frame(width: 50)
                        .disabled(row.donorID == nil)
                    }
                }
            }
            .onChange(of: viewModel.focusedRowID) { newID in
                focusedRowID = newID
            }

            // Optionally, a button to finalize & save all rows into the donation table:
//            HStack {
//                Spacer()
//                Button("Save Batch") {
//                    Task {
//                        await viewModel.saveBatch()
//                    }
//                }
//                .padding(.bottom)
//            }
        }
//        .padding(.horizontal)
            // Optional: load donors or do any setup
//            .task {
//                // If you want to ensure donors are loaded (or do other DB tasks)
//                // you can call:
//                // try? await donorObject.loadDonors()
//            }
        .navigationTitle("Batch Donations")
    }
}


// MARK: - ViewModel
class BatchDonationViewModel: ObservableObject {
    
    @Published var globalDonation: String = "10.00"
    
    // Each row in the list
    @Published var rows: [RowEntry] = []
    
    // Keep track of which row we should focus next
    @Published var focusedRowID: UUID? = nil
        // MARK: - Private Properties
        private let repository: any DonorSpecificRepositoryProtocol

        
//        // MARK: - Initialization
//        init(repository: DonorRepository = DonorRepository()) {
//            self.repository = repository
//        }
    init(repository: DonorRepository = DonorRepository()) {
        self.repository = repository
            // Start with one row
        rows.append(RowEntry())
    }
    
    struct RowEntry: Identifiable {
        let id = UUID()
        var donorID: Int? = nil
        var displayInfo: String = ""
        var donationOverride: String = ""
        var isValidDonor: Bool = false
    }
    
    /// Adds a new blank row at the bottom
    func addRow() {
        rows.append(RowEntry())
    }
    
    
    func getDonor(_ id: Int) async throws -> Donor? {
        let donor = try await repository.getOne(id)
        return donor
    }
    
    /// Attempt to find a donor by ID, then mark the row with success/failure.
    /// Pass in `DonorObjectClass` so we can call the real DB.
    func findDonor(for rowID: UUID) async {
        guard let rowIndex = rows.firstIndex(where: { $0.id == rowID }) else { return }
        guard let donorID = rows[rowIndex].donorID else { return }
        
        do {
            // Attempt a real DB fetch:
            if let matchedDonor = try await repository.getOne(donorID) {
//            if let matchedDonor = try await donorObject.getDonor(donorID) {
                let displayName = "\(matchedDonor.company ?? "") \(matchedDonor.lastName ?? "") \(matchedDonor.firstName ?? "")"
                let address = matchedDonor.address ?? ""
                
                // Update row
                await MainActor.run {
                    rows[rowIndex].displayInfo = "\(displayName) | \(address)"
                    rows[rowIndex].donationOverride = globalDonation
                    rows[rowIndex].isValidDonor = true
                }
                
                // Now add a new row and shift focus to it
                await MainActor.run {
                    addRow()
                    focusedRowID = rows.last?.id
                }
            } else {
                // If not found
                await MainActor.run {
                    rows[rowIndex].displayInfo = "Donor not found"
                    rows[rowIndex].donationOverride = ""
                    rows[rowIndex].isValidDonor = false
                }
            }
        } catch {
            // Database error or something else
            await MainActor.run {
                rows[rowIndex].displayInfo = "Error: \(error.localizedDescription)"
                rows[rowIndex].donationOverride = ""
                rows[rowIndex].isValidDonor = false
            }
        }
    }
    
    /// Saves each row as a new donation in the DB (optional).
    func saveBatch(donorObject: DonorObjectClass,
                   donationObject: DonationObjectClass) async {
        for row in rows {
            guard row.isValidDonor,
                  let donorID = row.donorID,
                  let matchedDonor = try? await donorObject.getDonor(donorID)
            else { continue }
            
            let donationAmtText = row.donationOverride.isEmpty
                ? globalDonation
                : row.donationOverride
            
            let donationAmt = Double(donationAmtText) ?? 0.0
            
            // Create a new donation
            var newDonation = Donation(
                donorId: matchedDonor.id,
                amount: donationAmt,
                donationType: .cash,  // or .check, etc.
                donationDate: Date()
            )
            
            do {
                // Insert into your DB
                try await donationObject.addDonation(newDonation)
            } catch {
                print("Failed saving donation for donor \(donorID): \(error)")
            }
        }
        
        // Optionally, clear or reset
        await MainActor.run {
            rows = [RowEntry()] // back to one empty row
        }
    }
}

