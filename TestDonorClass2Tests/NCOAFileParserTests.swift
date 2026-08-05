//
//  NCOAFileParserTests.swift
//  TestDonorClass2Tests
//

import Foundation
import Testing
@testable import TestDonorClass2

struct NCOAFileParserTests {

    private let parser = NCOAFileParser()

    private static let header = "idnum,title,first,last,company,address,address2,city,state,zip,oaddress,oaddress2,ocity,ostate,ozipcode,movetype_,movedate_"

    /// The real files arrive with Windows line endings.
    private func temporaryFile(rows: [String], header: String = NCOAFileParserTests.header) throws -> URL {
        let contents = ([header] + rows).joined(separator: "\r\n") + "\r\n"
        let url = FileManager.default.temporaryDirectory
            .appending(path: "ncoa-\(UUID().uuidString).csv")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Happy path

    @Test func parsesARowIntoTypedValues() throws {
        let url = try temporaryFile(rows: [
            "2755,Mr.,Yaakov,Blau,,1785 E 27th St,,Brooklyn,NY,11229-2510,2277 Homecrest Ave,6G,Brooklyn,NY,11229-4121,F,202503"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let output = try parser.parse(fileAt: url)

        #expect(output.records.count == 1)
        #expect(output.unreadableRowNumbers.isEmpty)

        let record = try #require(output.records.first)
        #expect(record.donorId == 2755)
        #expect(record.firstName == "Yaakov")
        #expect(record.lastName == "Blau")
        #expect(record.newAddress.street == "1785 E 27th St")
        #expect(record.newAddress.zip == "11229-2510")
        #expect(record.oldAddress.street == "2277 Homecrest Ave")
        #expect(record.oldAddress.suite == "6G")
        #expect(record.moveType == .family)
    }

    @Test func windowsLineEndingsDoNotLeakIntoTheLastColumn() throws {
        let url = try temporaryFile(rows: [
            "164,Mr,Stuart,Sloane,,384 Spring Dr,,East Meadow,NY,11554-2276,25 Michael Rd,,Syosset,NY,11791-6401,I,202503"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let record = try #require(try parser.parse(fileAt: url).records.first)

        #expect(record.moveType == .individual)
        #expect(record.moveDate != nil)
    }

    @Test func moveDateBecomesTheFirstOfThatMonth() throws {
        let url = try temporaryFile(rows: [
            "164,,Stuart,Sloane,,384 Spring Dr,,East Meadow,NY,11554,25 Michael Rd,,Syosset,NY,11791,I,202409"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let record = try #require(try parser.parse(fileAt: url).records.first)
        let moveDate = try #require(record.moveDate)
        let components = Calendar.current.dateComponents([.year, .month], from: moveDate)

        #expect(components.year == 2024)
        #expect(components.month == 9)
    }

    // MARK: - Blank handling

    @Test func blankSecondaryLineBecomesNilRatherThanWhitespace() throws {
        let url = try temporaryFile(rows: [
            "2755,,Yaakov,Blau,, 1785 E 27th St , ,Brooklyn,NY,11229,2277 Homecrest Ave,6G,Brooklyn,NY,11229,F,202503"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let record = try #require(try parser.parse(fileAt: url).records.first)

        #expect(record.newAddress.suite == nil)
        #expect(record.newAddress.street == "1785 E 27th St")
    }

    @Test func unrecognizedMoveTypeIsReportedAsUnknownRatherThanGuessed() throws {
        let url = try temporaryFile(rows: [
            "2755,,Yaakov,Blau,,1785 E 27th St,,Brooklyn,NY,11229,2277 Homecrest Ave,,Brooklyn,NY,11229,,202503"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let record = try #require(try parser.parse(fileAt: url).records.first)

        #expect(record.moveType == nil)
    }

    // MARK: - Bad rows

    @Test func rowsWithoutAUsableIdAreReportedNotDropped() throws {
        let url = try temporaryFile(rows: [
            "2755,,Yaakov,Blau,,1785 E 27th St,,Brooklyn,NY,11229,2277 Homecrest Ave,,Brooklyn,NY,11229,F,202503",
            "notanumber,,Someone,Else,,1 Main St,,Brooklyn,NY,11229,2 Main St,,Brooklyn,NY,11229,F,202503"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let output = try parser.parse(fileAt: url)

        #expect(output.records.count == 1)
        #expect(output.unreadableRowNumbers == [3])
    }

    @Test func rowWithoutANewStreetIsUnusable() throws {
        let url = try temporaryFile(rows: [
            "2755,,Yaakov,Blau,,,,Brooklyn,NY,11229,2277 Homecrest Ave,,Brooklyn,NY,11229,F,202503",
            "164,,Stuart,Sloane,,384 Spring Dr,,East Meadow,NY,11554,25 Michael Rd,,Syosset,NY,11791,I,202503"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let output = try parser.parse(fileAt: url)

        #expect(output.records.count == 1)
        #expect(output.records[0].donorId == 164)
        #expect(output.unreadableRowNumbers == [2])
    }

    // MARK: - Rejected files

    @Test func aFileMissingRequiredColumnsIsRejected() throws {
        let url = try temporaryFile(
            rows: ["2755,Yaakov,Blau"],
            header: "idnum,first,last"
        )
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: NCOAFileParserError.missingColumns([
            "address", "city", "state", "zip", "oaddress", "ocity", "ostate", "ozipcode"
        ])) {
            try parser.parse(fileAt: url)
        }
    }

    @Test func aFileWithNoUsableRowsIsRejected() throws {
        let url = try temporaryFile(rows: [
            "notanumber,,Someone,Else,,1 Main St,,Brooklyn,NY,11229,2 Main St,,Brooklyn,NY,11229,F,202503"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: NCOAFileParserError.noUsableRows) {
            try parser.parse(fileAt: url)
        }
    }

    @Test func aMissingFileIsReportedAsUnreadable() {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "does-not-exist-\(UUID().uuidString).csv")

        #expect(throws: NCOAFileParserError.self) {
            try parser.parse(fileAt: url)
        }
    }
}
