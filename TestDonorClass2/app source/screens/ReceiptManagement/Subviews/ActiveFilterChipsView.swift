//
//  ActiveFilterChipsView.swift
//  TestDonorClass2
//
//  Surfaces the active amount-range filter as a tappable chip so the
//  user can see and clear it without scrolling back to the filter card.
//

import SwiftUI

struct ActiveFilterChipsView: View {
    let minAmount: Double?
    let maxAmount: Double?
    let onClear: () -> Void

    var body: some View {
        if minAmount != nil || maxAmount != nil {
            HStack {
                Button(action: onClear) {
                    HStack(spacing: 6) {
                        Text(rangeLabel)
                            .font(.caption)
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15), in: .capsule)
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
    }

    private var rangeLabel: String {
        let minText = minAmount.map { $0.formatted(.currency(code: "USD")) } ?? "Any"
        let maxText = maxAmount.map { $0.formatted(.currency(code: "USD")) } ?? "Any"
        return "\(minText) – \(maxText)"
    }
}
