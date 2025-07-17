import SwiftUI

struct DonorResultRow: View {
    let donor: Donor
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formatName())
                .font(.headline)
                .foregroundColor(.primary)

            if let company = donor.company, !company.isEmpty {
                Text(company)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let address = donor.address, !address.isEmpty {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let city = donor.city, let state = donor.state {
                Text("\(city), \(state)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }

    private func formatName() -> String {
        var nameComponents = [String]()
        if let firstName = donor.firstName { nameComponents.append(firstName) }
        if let lastName = donor.lastName { nameComponents.append(lastName) }
        let joinedName = nameComponents.joined(separator: " ")
        return joinedName.isEmpty ? (donor.company ?? "Unknown Donor") : joinedName
    }
}