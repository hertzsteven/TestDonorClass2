//
//  ReceiptDetailViewModel.swift
//  TestDonorClass2
//
//  Loads and exposes the full database record behind a receipt row.
//  All display-ready strings are computed here so the view stays
//  purely declarative.
//

import Foundation

@MainActor
@Observable
final class ReceiptDetailViewModel {
    private(set) var donation: Donation?
    private(set) var donor: Donor?
    private(set) var campaign: Campaign?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let receiptItem: ReceiptItem
    private let dataProvider: ReceiptDetailDataProvider

    init(receiptItem: ReceiptItem, donationRepository: DonationRepository) {
        self.receiptItem = receiptItem
        self.dataProvider = ReceiptDetailDataProvider(donationRepository: donationRepository)
    }

    // MARK: - Loading

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let details = try await dataProvider.loadDetails(for: receiptItem)
            donation = details.donation
            donor = details.donor
            campaign = details.campaign
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Donor display helpers

    var donorDisplayName: String {
        guard let donor else { return donation?.isAnonymous == true ? "Anonymous" : "Unknown" }
        let first = donor.firstName ?? ""
        let last = donor.lastName ?? ""
        let name = "\(first) \(last)".trimmingCharacters(in: .whitespaces)

        if let salutation = donor.salutation, !salutation.isEmpty {
            let formatted = salutation.hasSuffix(".") ? salutation : "\(salutation)."
            return "\(formatted) \(name.isEmpty ? donor.company ?? "Unknown" : name)"
        }
        return name.isEmpty ? donor.company ?? "Unknown" : name
    }

    var donorCompany: String? {
        guard let company = donor?.company, !company.isEmpty else { return nil }
        return company
    }

    var donorAddress: String? {
        guard let donor else { return nil }
        let street = DonorAddressFormatter.formatStreetLine(
            address: donor.address,
            suite: donor.suite,
            additionalLine: donor.addl_line
        )
        var lines: [String] = []
        if let street, !street.isEmpty { lines.append(street) }
        var cityStateZip: [String] = []
        if let c = donor.city, !c.isEmpty { cityStateZip.append(c) }
        if let s = donor.state, !s.isEmpty { cityStateZip.append(s) }
        if let z = donor.zip, !z.isEmpty { cityStateZip.append(z) }
        if !cityStateZip.isEmpty { lines.append(cityStateZip.joined(separator: ", ")) }
        return lines.isEmpty ? nil : lines.joined(separator: "\n")
    }

    var donorPhone: String? {
        guard let phone = donor?.phone, !phone.isEmpty else { return nil }
        return phone
    }

    var donorEmail: String? {
        guard let email = donor?.email, !email.isEmpty else { return nil }
        return email
    }

    // MARK: - Campaign display helper

    var campaignDisplayName: String? {
        campaign?.name
    }
}
