import Foundation

/// Builds [`ReceiptFieldValues`](ReceiptFieldValues) for template-based receipt modes.
///
/// Letter copy is held as **templates** containing simple `{placeholder}`
/// markers that are substituted at print time. Default greeting and body
/// ship with the app; both can be overridden per organization in Settings.
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

    /// - Parameter printDate: The date the receipt is being produced. Used for
    ///   the letter's `{date}` placeholder and the `letterDate` field. Defaults
    ///   to `Date()` so production call sites get "today" automatically; tests
    ///   inject a fixed value for deterministic output.
    static func fieldValues(
        donation: DonationInfo,
        organization: OrganizationInfo,
        letterTemplates: ReceiptLetterTemplates = .default,
        printDate: Date = Date()
    ) -> ReceiptFieldValues {
        _ = organization
        let formattedPrintDate = formattedLetterDate(printDate)
        let placeholders = placeholderValues(for: donation, printDate: formattedPrintDate)
        let greeting = letterTemplates.greeting.isEmpty ? defaultGreetingTemplate : letterTemplates.greeting
        let body = letterTemplates.body.isEmpty ? defaultBodyTemplate : letterTemplates.body
        return ReceiptFieldValues(
            letterDate: formattedPrintDate,
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
    /// The `{donorName}` placeholder uses the donor's *titled* name (e.g.
    /// "Mr. Steven Hertz") when a title is present, falling back to plain
    /// name when not, and to `Friend` for anonymous gifts.
    private static func placeholderValues(for donation: DonationInfo, printDate: String) -> [String: String] {
        let rawName = donation.donorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let isAnonymous = rawName.isEmpty || rawName.localizedStandardContains("anonymous")
        let donorName = isAnonymous ? "Friend" : donation.formattedDonorName
        return [
            "donorName": donorName,
            "amount": donation.donationAmount.formatted(.currency(code: "USD")),
            "date": printDate,
        ]
    }

    /// Formats the print date for the letter (e.g. "May 26, 2026").
    private static func formattedLetterDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
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
