//
//  ReceiptFiltersView.swift
//  TestDonorClass2
//
//  Grouped filter card containing search field and amount range fields.
//  Re-applies filters via the `onChange` closure whenever inputs change.
//

import SwiftUI

/// Identifies each focusable field in the filters card. Lifting focus
/// here (instead of letting SwiftUI infer it from view identity)
/// prevents the system from spontaneously re-granting focus to Min or
/// Max when the chip button appears/disappears or when the filter
/// inputs are cleared from outside.
enum ReceiptFilterField: Hashable {
    case search
    case minAmount
    case maxAmount
}

struct ReceiptFiltersView: View {
    @Binding var searchText: String
    @Binding var minAmount: Double?
    @Binding var maxAmount: Double?
    let onChange: () -> Void

    @FocusState private var focusedField: ReceiptFilterField?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ReceiptSearchRow(
                searchText: $searchText,
                focusedField: $focusedField,
                onChange: onChange
            )
            ReceiptAmountRangeRow(
                minAmount: $minAmount,
                maxAmount: $maxAmount,
                focusedField: $focusedField,
                onChange: onChange
            )
        }
        .padding(12)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: .rect(cornerRadius: 12)
        )
        .padding(.horizontal)
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty && focusedField == .search {
                focusedField = nil
            }
        }
        .onChange(of: minAmount) { _, newValue in
            if newValue == nil && focusedField == .minAmount {
                focusedField = nil
            }
        }
        .onChange(of: maxAmount) { _, newValue in
            if newValue == nil && focusedField == .maxAmount {
                focusedField = nil
            }
        }
    }
}

private struct ReceiptSearchRow: View {
    @Binding var searchText: String
    @FocusState.Binding var focusedField: ReceiptFilterField?
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search receipts", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .search)
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
    @FocusState.Binding var focusedField: ReceiptFilterField?
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
            .focused($focusedField, equals: .minAmount)
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
            .focused($focusedField, equals: .maxAmount)
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
