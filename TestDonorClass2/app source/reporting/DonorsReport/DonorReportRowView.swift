//
//  DonorReportRowView.swift
//  TestDonorClass2
//

import SwiftUI

/// One donor row in the Donors report list, including address lines.
struct DonorReportRowView: View {
    let donor: Donor

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text(displayName)
                    .font(.headline)
                    .lineLimit(2)

                Spacer(minLength: 8)

                if let id = donor.id {
                    Text("ID \(id)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            if donor.currentAddress.displayLines.isEmpty {
                Text("No address")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(donor.currentAddress.displayLines, id: \.self) { line in
                    Text(line)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Text(emailText)
                .font(.subheadline)
                .foregroundStyle(hasEmail ? .primary : .secondary)

            Text(dateCaption)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var displayName: String {
        let trimmed = donor.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        return donor.company?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? "Unknown"
    }

    private var hasEmail: Bool {
        !(donor.email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private var emailText: String {
        if let email = donor.email?.trimmingCharacters(in: .whitespacesAndNewlines),
           !email.isEmpty {
            return email
        }
        return "No email"
    }

    private var dateCaption: String {
        let added = donor.createdAt.formatted(date: .abbreviated, time: .omitted)
        let updated = donor.updatedAt.formatted(date: .abbreviated, time: .omitted)
        return "Added \(added) · Updated \(updated)"
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
