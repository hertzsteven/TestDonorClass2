//
//  DonorAddress.swift
//  TestDonorClass2
//

import Foundation

/// The six postal components of a donor address grouped into one value so they
/// can be compared and carried around as a unit.
struct DonorAddress: Equatable, Hashable, Sendable {
    var street: String?
    var additionalLine: String?
    var suite: String?
    var city: String?
    var state: String?
    var zip: String?

    init(
        street: String? = nil,
        additionalLine: String? = nil,
        suite: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zip: String? = nil
    ) {
        self.street = street
        self.additionalLine = additionalLine
        self.suite = suite
        self.city = city
        self.state = state
        self.zip = zip
    }

    /// True when none of the components carry any text.
    var isEmpty: Bool {
        components.allSatisfy { Self.comparable($0).isEmpty }
    }

    /// Multi-line rendering for read-only display.
    var displayLines: [String] {
        var lines: [String] = []
        if let streetLine = DonorAddressFormatter.formatStreetLine(
            address: street,
            suite: suite,
            additionalLine: additionalLine
        ) {
            lines.append(streetLine)
        }

        let cityStateZip = [Self.trimmed(city), Self.trimmed(state), Self.trimmed(zip)]
            .compactMap { $0 }
            .joined(separator: " ")
        if !cityStateZip.isEmpty {
            lines.append(cityStateZip)
        }
        return lines
    }

    /// Whitespace, letter casing, punctuation and USPS abbreviations are all
    /// ignored, so re-typing "Avenue" as "Ave." is not treated as a move. ZIP
    /// codes compare on their first five digits.
    func matches(_ other: DonorAddress) -> Bool {
        comparableKey == other.comparableKey
    }

    private var comparableKey: [String] {
        [
            PostalAddressNormalizer.normalized(street),
            PostalAddressNormalizer.normalized(additionalLine),
            PostalAddressNormalizer.normalized(suite),
            PostalAddressNormalizer.normalized(city),
            PostalAddressNormalizer.normalized(state),
            PostalAddressNormalizer.normalizedZip(zip)
        ]
    }

    private var components: [String?] {
        [street, additionalLine, suite, city, state, zip]
    }

    private static func comparable(_ value: String?) -> String {
        trimmed(value)?.lowercased() ?? ""
    }

    private static func trimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
