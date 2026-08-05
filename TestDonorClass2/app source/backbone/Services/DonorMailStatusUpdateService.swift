//
//  DonorMailStatusUpdateService.swift
//  TestDonorClass2
//
//  Single responsibility: decide what a donor record should look like when its
//  address is reported undeliverable. The counterpart to
//  DonorAddressUpdateService, which handles the case where a new address exists.
//

import Foundation

struct DonorMailStatusUpdateService {

    /// Produces the donor that should be persisted when the address on file is
    /// known to be undeliverable, or nil when nothing needs to change.
    ///
    /// The address itself is left alone: it stays as the last known address, and
    /// keeping it is what lets the verification run again on a later import.
    /// `doNotMail` and `deceased` describe the person rather than the address, so
    /// they are never downgraded to `badAddress`.
    func donorFlaggedAsBadAddress(_ stored: Donor) -> Donor? {
        guard stored.resolvedMailStatus == .active else { return nil }

        var updated = stored
        updated.mailStatus = DonorMailStatus.badAddress.rawValue
        return updated
    }
}
