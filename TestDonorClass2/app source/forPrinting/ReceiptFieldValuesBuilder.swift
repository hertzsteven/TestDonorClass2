import Foundation

/// Builds [`ReceiptFieldValues`](ReceiptFieldValues) for template-based receipt modes.
///
/// Letter copy is held as **templates** containing simple `{placeholder}`
/// markers that are substituted at print time. The defaults below match the
/// first sample in [`ReceiptMockData`](ReceiptMockData) and can later be
/// overridden by per-organization Settings without changing call sites.
/// Supported placeholders: `{donorName}`, `{amount}`, `{date}`.
enum ReceiptFieldValuesBuilder {

    /// Default greeting template (used when org settings do not override it).
    static let defaultGreetingTemplate = "Dear {donorName},"

    /// Default body template (used when org settings do not override it).
    static let defaultBodyTemplate = """
        I want to express my heartfelt gratitude for your generous donation of {amount}. Your contribution is deeply appreciated and plays a crucial role in supporting our mission to assist those in need.

        Your partnership makes a significant difference in their lives, providing them with hope and assistance during challenging times.

        May you be blessed abundantly for your kindness and generosity.
        """

    static func fieldValues(
        donation: DonationInfo,
        organization: OrganizationInfo,
        letterTemplates: ReceiptLetterTemplates = .default
    ) -> ReceiptFieldValues {
        _ = organization
        let placeholders = placeholderValues(for: donation)
        let greeting = letterTemplates.greeting.isEmpty ? defaultGreetingTemplate : letterTemplates.greeting
        let body = letterTemplates.body.isEmpty ? defaultBodyTemplate : letterTemplates.body
        return ReceiptFieldValues(
            letterDate: donation.date,
            letterGreeting: substitute(greeting, with: placeholders),
            letterBody: substitute(body, with: placeholders),
            donorName: donation.formattedDonorName,
            donorAddressBlock: donation.formattedAddress,
            receiptNumber: formattedReceiptNumber(donation.receiptNumber),
            receiptDate: donation.date,
            donationAmount: formattedDonation(donation.donationAmount)
        )
    }

    /// Replaces `{key}` markers in `template` with values from `placeholders`.
    static func substitute(_ template: String, with placeholders: [String: String]) -> String {
        var output = template
        for (key, value) in placeholders {
            output = output.replacing("{\(key)}", with: value)
        }
        return output
    }

    /// Values used for `{donorName}`, `{amount}`, `{date}` substitution.
    /// Falls back to `Friend` when no usable donor name exists (anonymous gifts).
    private static func placeholderValues(for donation: DonationInfo) -> [String: String] {
        let rawName = donation.donorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let donorName = (rawName.isEmpty || rawName.localizedStandardContains("anonymous"))
            ? "Friend"
            : rawName
        return [
            "donorName": donorName,
            "amount": donation.donationAmount.formatted(.currency(code: "USD")),
            "date": donation.date,
        ]
    }

    private static func formattedReceiptNumber(_ receiptNumber: String?) -> String {
        guard let raw = receiptNumber?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return ""
        }
        if raw.localizedStandardContains("receipt") {
            return raw
        }
        return "Receipt #: \(raw)"
    }

    private static func formattedDonation(_ amount: Double) -> String {
        "Donation: \(amount.formatted(.currency(code: "USD")))"
    }
}
