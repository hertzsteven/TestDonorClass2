//
// DonationIncentiveRowView.swift
// TestDonorClass2
//

import SwiftUI

struct DonationIncentiveRowView: View {
    let incentive: DonationIncentive
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(incentive.name)
                    .font(.headline)
                Spacer()
                Text(String(format: "$%.2f", incentive.dollarAmount))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let description = incentive.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                StatusBadge(status: incentive.status.rawValue)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Badge View
private struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
    
    private var backgroundColor: Color {
        switch status.lowercased() {
        case "active":
            return .green
        case "inactive":
            return .gray
        case "archived":
            return .red
        default:
            return .blue
        }
    }
}

// MARK: - Preview
#Preview {
    List {
        DonationIncentiveRowView(incentive: DonationIncentive(
            name: "Early Bird Special",
            description: "Special discount for early donors",
            dollarAmount: 100.00,
            status: .active
        ))
    }
}

