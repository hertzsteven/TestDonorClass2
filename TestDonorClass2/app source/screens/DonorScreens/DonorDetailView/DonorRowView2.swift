    //
    //  DonorRowView2.swift
    //  TestDonorClass2
    //
    //  Created by Steven Hertz on 2/10/25.
    //

    import SwiftUI

    struct DonorRowView2: View {
        let donor: Donor
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(formatName(donor))
                        .font(.headline)
                    Spacer()
                    if let company = donor.company {
                        Text(company)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack {
                    if let email = donor.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    if let city = donor.city, let state = donor.state {
                        Text("\(city), \(state)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack {
                    if let phone = donor.phone {
                        Text(phone)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
    //                if let city = donor.city, let state = donor.state {
    //                    Text("\(city), \(state)")
    //                        .font(.subheadline)
    //                        .foregroundColor(.gray)
    //                }
                }
            }
            .padding(.vertical, 4)
        }
        
        private func formatName(_ donor: Donor) -> String {
            var components: [String] = []
            if let salutation = donor.salutation { components.append(salutation) }
            if let firstName = donor.firstName { components.append(firstName) }
            if let lastName = donor.lastName { components.append(lastName) }
            return components.joined(separator: " ")
        }
    }

    #Preview {
        NavigationStack {
            DonorRowView2(donor: Donor(
                company: "Tech Corp",
                salutation: "Mr.",
                firstName: "John",
                lastName: "Doe",
                city: "San Francisco",
                state: "CA",
                email: "john.doe@example.com",
                phone: "555-1234"
            )).padding(.horizontal, 24)
            .environmentObject(DonorObjectClass())
            .environmentObject(CampaignObjectClass())
            .environmentObject(DonationIncentiveObjectClass())
            .environmentObject(DefaultDonationSettingsViewModel())
            .environmentObject(DonationObjectClass())
        }
    }
