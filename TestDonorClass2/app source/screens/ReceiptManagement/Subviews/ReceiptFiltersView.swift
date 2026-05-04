//
//  ReceiptFiltersView.swift
//  TestDonorClass2
//
//  Grouped filter card containing search field and amount range fields.
//  Re-applies filters via the `onChange` closure whenever inputs change.
//

import SwiftUI

struct ReceiptFiltersView: View {
    @Binding var searchText: String
    @Binding var minAmount: Double?
    @Binding var maxAmount: Double?
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ReceiptSearchRow(searchText: $searchText, onChange: onChange)
            ReceiptAmountRangeRow(
                minAmount: $minAmount,
                maxAmount: $maxAmount,
                onChange: onChange
            )
        }
        .padding(12)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: .rect(cornerRadius: 12)
        )
        .padding(.horizontal)
    }
}

private struct ReceiptSearchRow: View {
    @Binding var searchText: String
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search receipts", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: searchText) { _, _ in onChange() }

            if !searchText.isEmpty {
                Button("Clear search", systemImage: "xmark.circle.fill") {
                    searchText = ""
                    onChange()
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ReceiptAmountRangeRow: View {
    @Binding var minAmount: Double?
    @Binding var maxAmount: Double?
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("Amount:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField(
                "Min",
                value: $minAmount,
                format: .currency(code: "USD")
            )
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: 120)
            .onChange(of: minAmount) { _, _ in onChange() }

            Text("–")
                .foregroundStyle(.secondary)

            TextField(
                "Max",
                value: $maxAmount,
                format: .currency(code: "USD")
            )
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: 120)
            .onChange(of: maxAmount) { _, _ in onChange() }

            Spacer()

            if minAmount != nil || maxAmount != nil {
                Button("Clear amount filter", systemImage: "xmark.circle.fill") {
                    minAmount = nil
                    maxAmount = nil
                    onChange()
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
            }
        }
    }
}
