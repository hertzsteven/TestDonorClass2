//
//  BatchDonationRowView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/30/25.
//

import SwiftUI
/// A smaller, separate subview that handles one row of data.
struct BatchDonationRowView: View {
    @Binding var row: BatchDonationViewModel.RowEntry
    @FocusState var focusedRowID: UUID?
    let onFind: () -> Void
    
    // Predefine a NumberFormatter to avoid repeated creation
    static let donorIDFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .none
        return f
    }()
    
    var body: some View {
        HStack {
            // Donor Code (ID) text field
            TextField("Donor ID",
                      value: $row.donorID,
                      formatter: Self.donorIDFormatter
            )
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
            Button(action: onFind) {
                Image(systemName: "magnifyingglass")
            }
            .frame(width: 50)
            .disabled(row.donorID == nil)
        }
    }
}
