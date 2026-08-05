//
//  ExternalDonationFileParser.swift
//  TestDonorClass2
//
//  Single responsibility: turn an external-donations CSV into typed records.
//  Knows nothing about donors or the database.
//

import Foundation
import SwiftCSV

struct ExternalDonationFileParser {

    private enum Column {
        static let referenceNumber = "Reference Number"
        static let source = "Source"
        static let date = "Date"
        static let firstName = "First Name"
        static let lastName = "Last Name"
        static let organization = "Organization/Company Name"
        static let amount = "Gross Amount"
        static let street = "Street Address"
        static let suite = "Suite/Apt Number"
        static let city = "City"
        static let state = "State"
        static let zip = "Zip"
        static let email = "Email"
        static let phone = "Phone"
        static let memo = "Memo/Notes"
        static let hebrewName = "Hebrew Name"
        static let mothersHebrewName = "Mother's Hebrew Name"
        static let details = "Details"
        static let product = "Product"
        static let messageID = "Message ID"
        static let reviewNeeded = "Review Needed"

        static let required = [source, date, amount]

        /// Present only on NCOA update files. Used as a wrong-file guard.
        static let ncoaUpdateMarker = "idnum"
        static let ncoaOldAddressMarker = "oaddress"
    }

    struct Output: Sendable {
        let records: [ExternalDonationRecord]
        let unreadableRowNumbers: [Int]
    }

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func parse(fileAt url: URL) throws -> Output {
        let needsScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let csv: CSV<Named>
        do {
            csv = try CSV<Named>(url: url, delimiter: .comma, encoding: .utf8)
        } catch {
            throw NCOAFileParserError.unreadableFile(error.localizedDescription)
        }

        let header = Set(csv.header.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })

        if header.contains(Column.ncoaUpdateMarker) || header.contains(Column.ncoaOldAddressMarker) {
            throw NCOAFileParserError.wrongFileType(
                expected: "external donations file",
                found: "NCOA address file"
            )
        }

        let missing = Column.required.filter { !header.contains($0) }
        guard missing.isEmpty else {
            throw NCOAFileParserError.missingColumns(missing)
        }

        var records: [ExternalDonationRecord] = []
        var unreadable: [Int] = []

        for (offset, row) in csv.rows.enumerated() {
            let lineNumber = offset + 2
            guard let record = Self.record(from: row, rowNumber: lineNumber, calendar: calendar) else {
                unreadable.append(lineNumber)
                continue
            }
            records.append(record)
        }

        guard !records.isEmpty else {
            throw NCOAFileParserError.noUsableRows
        }

        return Output(records: records, unreadableRowNumbers: unreadable)
    }

    // MARK: - Row conversion

    private static func record(
        from row: [String: String],
        rowNumber: Int,
        calendar: Calendar
    ) -> ExternalDonationRecord? {
        guard let source = ExternalDonationSource.parse(value(row, Column.source)) else {
            return nil
        }
        guard let date = parseDate(value(row, Column.date), calendar: calendar) else {
            return nil
        }
        guard let amount = parseAmount(value(row, Column.amount)), amount > 0 else {
            return nil
        }

        return ExternalDonationRecord(
            rowNumber: rowNumber,
            referenceNumber: value(row, Column.referenceNumber),
            source: source,
            date: date,
            amount: amount,
            firstName: value(row, Column.firstName),
            lastName: value(row, Column.lastName),
            organizationName: value(row, Column.organization),
            address: DonorAddress(
                street: value(row, Column.street),
                suite: value(row, Column.suite),
                city: value(row, Column.city),
                state: value(row, Column.state),
                zip: value(row, Column.zip)
            ),
            email: value(row, Column.email),
            phone: value(row, Column.phone),
            memo: value(row, Column.memo),
            hebrewName: value(row, Column.hebrewName),
            mothersHebrewName: value(row, Column.mothersHebrewName),
            details: value(row, Column.details),
            product: value(row, Column.product),
            messageID: value(row, Column.messageID),
            reviewNeeded: value(row, Column.reviewNeeded)
        )
    }

    private static func value(_ row: [String: String], _ column: String) -> String? {
        guard let raw = row[column] else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func parseAmount(_ raw: String?) -> Double? {
        guard let raw else { return nil }
        let cleaned = raw
            .replacing("$", with: "")
            .replacing(",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned)
    }

    private static func parseDate(_ raw: String?, calendar: Calendar) -> Date? {
        guard let raw else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.date(from: raw)
    }
}
