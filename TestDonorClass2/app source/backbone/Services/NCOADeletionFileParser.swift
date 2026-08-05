//
//  NCOADeletionFileParser.swift
//  TestDonorClass2
//
//  Single responsibility: turn an NCOA delete file into typed records. Knows
//  nothing about donors or the database.
//

import Foundation
import SwiftCSV

struct NCOADeletionFileParser {

    /// Column names as the mailing service writes them. The delete file carries
    /// no new address, so there is no `city`, `state` or `zip`, and `address`
    /// holds the reason text rather than an address.
    private enum Column {
        static let donorId = "idnum"
        static let firstName = "first"
        static let lastName = "last"
        static let company = "company"
        static let reason = "address"

        static let oldStreet = "oaddress"
        static let oldSecondary = "oaddress2"
        static let oldCity = "ocity"
        static let oldState = "ostate"
        static let oldZip = "ozipcode"

        /// Without these the file cannot be interpreted safely.
        static let required = [donorId, oldStreet, oldCity, oldState, oldZip]

        /// Present only in the update file. Its absence is what distinguishes a
        /// delete file, whose required columns are otherwise a subset.
        static let updateFileMarker = "city"
    }

    struct Output: Sendable {
        let records: [NCOADeletionRecord]

        /// One-based line numbers in the file that could not be interpreted,
        /// almost always a missing or non-numeric id.
        let unreadableRowNumbers: [Int]
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

        // Checked before the required columns, so picking the update file here
        // gives a useful message instead of silently flagging good donors.
        guard !header.contains(Column.updateFileMarker) else {
            throw NCOAFileParserError.wrongFileType(
                expected: "NCOA delete file",
                found: "NCOA address update file"
            )
        }

        let missing = Column.required.filter { !header.contains($0) }
        guard missing.isEmpty else {
            throw NCOAFileParserError.missingColumns(missing)
        }

        var records: [NCOADeletionRecord] = []
        var unreadable: [Int] = []

        for (offset, row) in csv.rows.enumerated() {
            // Offset zero is the first row after the header line.
            let lineNumber = offset + 2

            guard let record = Self.record(from: row) else {
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

    private static func record(from row: [String: String]) -> NCOADeletionRecord? {
        guard let donorId = Int(value(row, Column.donorId) ?? "") else { return nil }

        let oldAddress = DonorAddress(
            street: value(row, Column.oldStreet),
            suite: value(row, Column.oldSecondary),
            city: value(row, Column.oldCity),
            state: value(row, Column.oldState),
            zip: value(row, Column.oldZip)
        )

        // With no address to verify against, the row cannot be acted on safely.
        guard oldAddress.street != nil else { return nil }

        return NCOADeletionRecord(
            donorId: donorId,
            firstName: value(row, Column.firstName) ?? "",
            lastName: value(row, Column.lastName) ?? "",
            company: value(row, Column.company) ?? "",
            reason: value(row, Column.reason),
            oldAddress: oldAddress
        )
    }

    private static func value(_ row: [String: String], _ column: String) -> String? {
        guard let raw = row[column] else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
