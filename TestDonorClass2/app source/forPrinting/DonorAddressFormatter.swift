import Foundation

/// Builds the single-line street portion of a printed donor address (no city/state/zip).
enum DonorAddressFormatter {

    /// Composes `address`, optional labeled `suite`, and optional `additionalLine` with comma separators.
    /// Returns `nil` when every input is empty or whitespace-only.
    static func formatStreetLine(
        address: String?,
        suite: String?,
        additionalLine: String?
    ) -> String? {
        let street = trimmedNonEmpty(address)
        let suiteFormatted = formattedSuite(suite)
        let addl = trimmedNonEmpty(additionalLine)

        let parts = [street, suiteFormatted, addl].compactMap { $0 }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: ", ")
    }

    private static func trimmedNonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func formattedSuite(_ suite: String?) -> String? {
        guard let raw = trimmedNonEmpty(suite) else { return nil }
        if suiteAlreadyHasUnitPrefix(raw) {
            return raw
        }
        return "Apt/Ste \(raw)"
    }

    private static func suiteAlreadyHasUnitPrefix(_ suite: String) -> Bool {
        let lower = suite.lowercased()
        if lower.hasPrefix("#") { return true }
        if lower.hasPrefix("apt/ste") { return true }

        let prefixes = [
            "apt ", "apt.",
            "ste ", "ste.",
            "suite ", "apartment ", "unit ",
        ]
        return prefixes.contains { lower.hasPrefix($0) }
    }
}
