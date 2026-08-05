//
//  NCOADeletionRecord.swift
//  TestDonorClass2
//
//  One row from an NCOA delete file: a donor who moved with no forwarding
//  address, so there is nothing to update and mail should stop.
//

import Foundation

struct NCOADeletionRecord: Sendable, Equatable {
    /// The donor this row claims to describe, taken from the file's `idnum`.
    let donorId: Int

    let firstName: String
    let lastName: String
    let company: String

    /// Why the mailing service gave up on the address, typically
    /// "Moved No Forwarding Address". Displayed, never stored.
    let reason: String?

    /// The address the mailing service found undeliverable. Used only to verify
    /// the record on file, and never written or cleared.
    let oldAddress: DonorAddress

    /// Name as it appears in the file, for display beside the address.
    var displayName: String {
        let personal = [firstName, lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if personal.isEmpty { return company }
        return company.isEmpty ? personal : "\(personal) (\(company))"
    }
}
