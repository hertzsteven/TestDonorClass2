//
//  NCOAFileParser.swift
//  TestDonorClass2
//
//  Single responsibility: turn an NCOA update CSV into typed records. Knows
//  nothing about donors or the database.
//

import Foundation
import SwiftCSV

struct NCOAFileParser {

    /// Column names as the mailing service writes them.
    private enum Column {
        static let donorId = "idnum"
        static let firstName = "first"
        static let lastName = "last"
        static let company = "company"

        static let newStreet = "address"
        static let newSecondary = "address2"
        static let newCity = "city"
        static let newState = "state"
        static let newZip = "zip"

        static let oldStreet = "oaddress"
        static let oldSecondary = "oaddress2"
        static let oldCity = "ocity"
        static let oldState = "ostate"
        static let oldZip = "ozipcode"

        static let moveType = "movetype_"
        static let moveDate = "movedate_"

        /// Without these the file cannot be interpreted safely.
        static let required = [
            donorId, newStreet, newCity, newState, newZip,
            oldStreet, oldCity, oldState, oldZip
        ]
    }

    struct Output: Sendable {
        let records: [NCOARecord]

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
        let missing = Column.required.filter { !header.contains($0) }
        guard missing.isEmpty else {
            throw NCOAFileParserError.missingColumns(missing)
        }

        var records: [NCOARecord] = []
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

    private static func record(from row: [String: String]) -> NCOARecord? {
        guard let donorId = Int(value(row, Column.donorId) ?? "") else { return nil }

        let newAddress = DonorAddress(
            street: value(row, Column.newStreet),
            suite: value(row, Column.newSecondary),
            city: value(row, Column.newCity),
            state: value(row, Column.newState),
            zip: value(row, Column.newZip)
        )
        let oldAddress = DonorAddress(
            street: value(row, Column.oldStreet),
            suite: value(row, Column.oldSecondary),
            city: value(row, Column.oldCity),
            state: value(row, Column.oldState),
            zip: value(row, Column.oldZip)
        )

        // A row with no new street has nothing to apply.
        guard newAddress.street != nil else { return nil }

        return NCOARecord(
            donorId: donorId,
            firstName: value(row, Column.firstName) ?? "",
            lastName: value(row, Column.lastName) ?? "",
            company: value(row, Column.company) ?? "",
            newAddress: newAddress,
            oldAddress: oldAddress,
            moveType: NCOAMoveType.resolve(value(row, Column.moveType)),
            moveDate: moveDate(from: value(row, Column.moveDate))
        )
    }

    /// Trimmed value, or nil when the column is absent or blank, so that a blank
    /// cell clears the corresponding donor field rather than writing whitespace.
    private static func value(_ row: [String: String], _ column: String) -> String? {
        guard let raw = row[column] else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// The file reports the move as `YYYYMM`.
    private static func moveDate(from rawValue: String?) -> Date? {
        guard let digits = rawValue?.filter(\.isNumber), digits.count == 6 else { return nil }
        guard let year = Int(digits.prefix(4)),
              let month = Int(digits.suffix(2)),
              (1...12).contains(month) else { return nil }

        return Calendar.current.date(from: DateComponents(year: year, month: month))
    }
}
