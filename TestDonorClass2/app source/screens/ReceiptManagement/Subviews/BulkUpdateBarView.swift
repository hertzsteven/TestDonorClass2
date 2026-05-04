//
//  BulkUpdateBarView.swift
//  TestDonorClass2
//
//  Bulk-promote bar on the Not-Requested tab. Lets the user move all
//  donations at-or-above a threshold into the Requested queue.
//

import SwiftUI

struct BulkUpdateBarView: View {
    @Binding var threshold: String
    let onSubmit: (Double) -> Void

    var body: some View {
        HStack {
            Text("Update donations ≥ $")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("Amount", text: $threshold)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
            Text("to Requested")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                if let amount = Double(threshold) {
                    onSubmit(amount)
                }
            } label: {
                Label("Update", systemImage: "arrow.right.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(Double(threshold) == nil)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
