//
//  DonorAddressUpdateService.swift
//  TestDonorClass2
//
//  Single responsibility: decide what a donor record should look like when its
//  address is being replaced. Keeps the move policy out of the edit screens so
//  every save path behaves identically.
//

import Foundation

struct DonorAddressUpdateService {

    /// Produces the donor that should be persisted for an edit.
    ///
    /// When the address changed, the address that was current beforehand is
    /// retained as the prior-address snapshot and a `badAddress` flag is
    /// cleared, since that flag described the address being replaced.
    /// `doNotMail` and `deceased` describe the person, so they are preserved.
    func donorForSaving(edited: Donor, stored: Donor) -> Donor {
        let oldAddress = stored.currentAddress
        guard !edited.currentAddress.matches(oldAddress) else {
            return edited
        }

        var updated = edited

        // A blank previous address is not worth snapshotting, and overwriting
        // with it would discard a genuinely useful older snapshot.
        if !oldAddress.isEmpty {
            updated.priorAddress = oldAddress
        }

        if updated.resolvedMailStatus == .badAddress {
            updated.mailStatus = DonorMailStatus.active.rawValue
        }

        return updated
    }
}
