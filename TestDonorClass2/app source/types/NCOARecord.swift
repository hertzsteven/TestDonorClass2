//
//  NCOARecord.swift
//  TestDonorClass2
//
//  One change-of-address row from an NCOA update file, already converted from
//  raw text into typed values.
//

import Foundation

struct NCOARecord: Sendable, Equatable {
    /// The donor this row claims to describe, taken from the file's `idnum`.
    let donorId: Int

    let firstName: String
    let lastName: String
    let company: String

    /// Where NCOA says the donor now lives. This is what gets written on apply.
    let newAddress: DonorAddress

    /// Where NCOA believes the donor lived. Used only to verify the record on
    /// file before anything is changed, and never written to the database.
    let oldAddress: DonorAddress

    let moveType: NCOAMoveType?
    let moveDate: Date?

    /// Name as it appears in the file, for display beside the addresses.
    var displayName: String {
        let personal = [firstName, lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if personal.isEmpty { return company }
        return company.isEmpty ? personal : "\(personal) (\(company))"
    }
}
