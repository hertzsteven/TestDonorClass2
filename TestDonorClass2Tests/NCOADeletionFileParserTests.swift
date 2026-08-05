//
//  NCOADeletionFileParserTests.swift
//  TestDonorClass2Tests
//

import Foundation
import Testing
@testable import TestDonorClass2

struct NCOADeletionFileParserTests {

    private let parser = NCOADeletionFileParser()

    private static let header = "idnum,title,first,last,company,address,oaddress,oaddress2,ocity,ostate,ozipcode"

    /// The real files arrive with Windows line endings.
    private func temporaryFile(rows: [String], header: String = NCOADeletionFileParserTests.header) throws -> URL {
        let contents = ([header] + rows).joined(separator: "\r\n") + "\r\n"
        let url = FileManager.default.temporaryDirectory
            .appending(path: "ncoadel-\(UUID().uuidString).csv")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Happy path

    @Test func parsesARowIntoTypedValues() throws {
        let url = try temporaryFile(rows: [
            "233,Mr.,Nason Arthur,Hurowitz,,Moved No Forwarding Address,19 Cardinal Rd,,Worcester,MA,01602-1765"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let output = try parser.parse(fileAt: url)

        #expect(output.records.count == 1)
        #expect(output.unreadableRowNumbers.isEmpty)

        let record = try #require(output.records.first)
        #expect(record.donorId == 233)
        #expect(record.firstName == "Nason Arthur")
        #expect(record.lastName == "Hurowitz")
        #expect(record.reason == "Moved No Forwarding Address")
        #expect(record.oldAddress.street == "19 Cardinal Rd")
        #expect(record.oldAddress.city == "Worcester")
        #expect(record.oldAddress.zip == "01602-1765")
        #expect(record.oldAddress.suite == nil)
    }

    @Test func theSecondaryLineBecomesTheSuite() throws {
        let url = try temporaryFile(rows: [
            "8865,Ms,Ellen L,Rosen,,Moved No Forwarding Address,40  Berkeley St,# 323,Boston,MA,02116-6316"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let record = try #require(try parser.parse(fileAt: url).records.first)

        #expect(record.oldAddress.suite == "# 323")
        #expect(record.oldAddress.street == "40  Berkeley St")
    }

    @Test func windowsLineEndingsDoNotLeakIntoTheLastColumn() throws {
        let url = try temporaryFile(rows: [
            "1302,Ms,Rose,Simon,,Moved No Forwarding Address,7483 Pershing Avenue,,Saint Louis,MO,63130-4021"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let record = try #require(try parser.parse(fileAt: url).records.first)

        #expect(record.oldAddress.zip == "63130-4021")
    }

    // MARK: - Bad rows

    @Test func rowsWithoutAUsableIdAreReportedNotDropped() throws {
        let url = try temporaryFile(rows: [
            "233,Mr.,Nason Arthur,Hurowitz,,Moved No Forwarding Address,19 Cardinal Rd,,Worcester,MA,01602-1765",
            "notanumber,Ms,Rose,Simon,,Moved No Forwarding Address,7483 Pershing Ave,,Saint Louis,MO,63130"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let output = try parser.parse(fileAt: url)

        #expect(output.records.count == 1)
        #expect(output.unreadableRowNumbers == [3])
    }

    @Test func rowWithoutAnUndeliverableStreetIsUnusable() throws {
        let url = try temporaryFile(rows: [
            "233,Mr.,Nason Arthur,Hurowitz,,Moved No Forwarding Address,,,Worcester,MA,01602-1765",
            "1302,Ms,Rose,Simon,,Moved No Forwarding Address,7483 Pershing Ave,,Saint Louis,MO,63130"
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        let output = try parser.parse(fileAt: url)

        #expect(output.records.count == 1)
        #expect(output.records[0].donorId == 1302)
        #expect(output.unreadableRowNumbers == [2])
    }

    // MARK: - Rejected files

    /// The delete file's required columns are a subset of the update file's, so
    /// without this guard the update file would flag every donor in it.
    @Test func theUpdateFileIsRejectedRatherThanFlaggingGoodDonors() throws {
        let updateHeader = "idnum,title,first,last,company,address,address2,city,state,zip,oaddress,oaddress2,ocity,ostate,ozipcode,movetype_,movedate_"
        let url = try temporaryFile(
            rows: ["2755,Mr.,Yaakov,Blau,,1785 E 27th St,,Brooklyn,NY,11229,2277 Homecrest Ave,6G,Brooklyn,NY,11229,F,202503"],
            header: updateHeader
        )
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: NCOAFileParserError.wrongFileType(
            expected: "NCOA delete file",
            found: "NCOA address update file"
        )) {
            try parser.parse(fileAt: url)
        }
    }

    @Test func aFileMissingRequiredColumnsIsRejected() throws {
        let url = try temporaryFile(
            rows: ["233,Nason Arthur,Hurowitz"],
            header: "idnum,first,last"
        )
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: NCOAFileParserError.missingColumns([
            "oaddress", "ocity", "ostate", "ozipcode"
        ])) {
            try parser.parse(fileAt: url)
        }
    }

    @Test func aFileWithNoUsableRowsIsRejected() throws {
        let url = try temporaryFile(rows: [
            "notanumber,Ms,Rose,Simon,,Moved No Forwarding Address,7483 Pershing Ave,,Saint Louis,MO,63130"
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
