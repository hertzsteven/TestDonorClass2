//
//  NCOAMoveDetailView.swift
//  TestDonorClass2
//

import SwiftUI

/// The move type and month the mailing service reported, shown as a footnote.
struct NCOAMoveDetailView: View {
    let record: NCOARecord

    var body: some View {
        if let description {
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var description: String? {
        var parts: [String] = []
        if let moveType = record.moveType {
            parts.append(moveType.displayName)
        }
        if let moveDate = record.moveDate {
            parts.append(moveDate.formatted(.dateTime.month(.wide).year()))
        }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
