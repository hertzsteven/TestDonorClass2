//
//  ExternalDonationFileParserTests.swift
//  TestDonorClass2Tests
//

import Foundation
import Testing
@testable import TestDonorClass2

struct ExternalDonationFileParserTests {

    private let parser = ExternalDonationFileParser()

    private static let header = "Reference Number,Source,Date,First Name,Last Name,Organization/Company Name,Gross Amount,Street Address,Suite/Apt Number,City,State,Zip,Email,Phone,Memo/Notes,Hebrew Name,Mother's Hebrew Name,Details,Product,Message ID,Review Needed"

    private func temporaryFile(rows: [String], header: String = ExternalDonationFileParserTests.header) throws -> URL {
        let contents = ([header] + rows).joined(separator: "\r\n") + "\r\n"
        let url = FileManager.default.temporaryDirectory
            .appending(path: "external-\(UUID().uuidString).csv")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test func parsesARowIntoTypedValues() throws {
        let url = try temporaryFile(rows: [
            "Certificate# 16625771,OJC,05/29/2026,malka,steinmetz,,5.00,,,,,,,,,,,,,,,"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let output = try parser.parse(fileAt: url)
        #expect(output.records.count == 1)
        #expect(output.unreadableRowNumbers.isEmpty)

        let record = try #require(output.records.first)
        #expect(record.source == .ojc)
        #expect(record.firstName == "malka")
        #expect(record.lastName == "steinmetz")
        #expect(record.amount == 5)
        #expect(record.referenceNumber == "Certificate# 16625771")
        #expect(record.importKey == "OJC#Certificate# 16625771")
    }

    @Test func parsesWebsiteAndReviewNeeded() throws {
        let url = try temporaryFile(rows: [
            "MSG-1,Website (Sola),06/03/2026,Ita,Garsek,,36.00,10 Main St,,Brooklyn,NY,11230,a@b.com,,,note,,,,,Sola name was 'Ita Garsek' — replaced with Tracker name"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let record = try #require(try parser.parse(fileAt: url).records.first)
        #expect(record.source == .website)
        #expect(record.hasReviewNeeded)
        #expect(record.address.street == "10 Main St")
        #expect(record.email == "a@b.com")
    }

    @Test func rejectsNCOAFile() throws {
        let header = "idnum,first,last,address,city,state,zip,oaddress,ocity,ostate,ozipcode"
        let url = try temporaryFile(
            rows: ["1,A,B,1 St,City,NY,11230,2 St,City,NY,11230"],
            header: header
        )
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: NCOAFileParserError.self) {
            try parser.parse(fileAt: url)
        }
    }

    @Test func missingRequiredColumnsFails() throws {
        let url = try temporaryFile(rows: ["x"], header: "Reference Number,First Name")
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: NCOAFileParserError.self) {
            try parser.parse(fileAt: url)
        }
    }

    @Test func badAmountBecomesUnreadable() throws {
        let url = try temporaryFile(rows: [
            "R1,Zelle,05/29/2026,A,B,,not-a-number,,,,,,,,,,,,,,,"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: NCOAFileParserError.self) {
            try parser.parse(fileAt: url)
        }
    }

    @Test func sourceMappingIsLocked() throws {
        #expect(ExternalDonationSource.ojc.donationType == .organizationDirect)
        #expect(ExternalDonationSource.donorsFund.donationType == .organizationDirect)
        #expect(ExternalDonationSource.website.donationType == .websiteCreditCard)
        #expect(ExternalDonationSource.zelle.donationType == .zelle)

        #expect(ExternalDonationSource.ojc.donorSource == .certificateOrganization)
        #expect(ExternalDonationSource.donorsFund.donorSource == .certificateOrganization)
        #expect(ExternalDonationSource.website.donorSource == .website)
        #expect(ExternalDonationSource.zelle.donorSource == .zelle)
    }

    @Test func parsesUnitedTiberiasUnifiedFile() throws {
        let url = URL(fileURLWithPath: "/Users/stevenhertz/Documents/Claude/Projects/Manage my work/united_tiberius_donations_unified.csv")
        guard FileManager.default.fileExists(atPath: url.path) else {
            return // Skip when the local backlog file is not on this machine.
        }

        let output = try parser.parse(fileAt: url)
        #expect(output.records.count == 257)
        #expect(output.unreadableRowNumbers.isEmpty)

        let bySource = Dictionary(grouping: output.records, by: \.source).mapValues(\.count)
        #expect(bySource[.donorsFund] == 85)
        #expect(bySource[.website] == 73)
        #expect(bySource[.zelle] == 61)
        #expect(bySource[.ojc] == 38)

        let total = output.records.map(\.amount).reduce(0, +)
        #expect(abs(total - 9_682.01) < 0.001)
    }
}
