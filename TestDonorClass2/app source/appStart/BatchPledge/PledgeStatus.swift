//
//  PledgeStatus.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 5/19/25.
//


//
//  PledgeStatus.swift
//  Batch pledges
//
//  Created by Steven Hertz on 5/18/25.
//

import SwiftUI

// --- Enums needed by BatchPledgeView/ViewModel ---
enum PledgeStatus: String, CaseIterable, Identifiable, Codable {
    case pledged = "Pledged"
    case partiallyFulfilled = "Partially Fulfilled"
    case fulfilled = "Fulfilled"
    case cancelled = "Cancelled"
    var id: String { self.rawValue }
    var displayName: String { self.rawValue }
}
