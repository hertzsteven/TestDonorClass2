//
//  Pledge.swift
//  TestDonorClass2
//
//  Created by Alex Carmack on 5/20/25.
//

import Foundation
import GRDB

// MARK: - Validation Errors
enum PledgeValidationError: LocalizedError {
    case invalidAmount
    case missingDonor
    case missingExpectedFulfillmentDate
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Pledge amount must be greater than zero."
        case .missingDonor:
            return "Pledge must be associated with a donor."
        case .missingExpectedFulfillmentDate:
            return "Pledge must have an expected fulfillment date."
        }
    }
}

// MARK: - Pledge Model
struct Pledge: Identifiable, Codable, FetchableRecord, PersistableRecord, Hashable {
    var id: Int?
    let uuid: String
    var donorId: Int?
    var campaignId: Int? // Optional: Pledges can be associated with campaigns
    var pledgeAmount: Double
    var status: PledgeStatus // From PledgeStatus.swift
    var expectedFulfillmentDate: Date
    var prayerNote: String?
    var notes: String? // General notes for the pledge
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Table Definition
    static let databaseTableName = "pledge"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let uuid = Column(CodingKeys.uuid)
        static let donorId = Column(CodingKeys.donorId)
        static let campaignId = Column(CodingKeys.campaignId)
        static let pledgeAmount = Column(CodingKeys.pledgeAmount)
        static let status = Column(CodingKeys.status)
        static let expectedFulfillmentDate = Column(CodingKeys.expectedFulfillmentDate)
        static let prayerNote = Column(CodingKeys.prayerNote)
        static let notes = Column(CodingKeys.notes)
        static let createdAt = Column(CodingKeys.createdAt)
        static let updatedAt = Column(CodingKeys.updatedAt)
    }
    
    // MARK: - GRDB Coding Keys
    enum CodingKeys: String, CodingKey, ColumnExpression {
        case id, uuid
        case donorId = "donor_id"
        case campaignId = "campaign_id"
        case pledgeAmount = "pledge_amount"
        case status
        case expectedFulfillmentDate = "expected_fulfillment_date"
        case prayerNote = "prayer_note"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Initialization
    init(
        id: Int? = nil,
        uuid: String = UUID().uuidString,
        donorId: Int?,
        campaignId: Int? = nil,
        pledgeAmount: Double,
        status: PledgeStatus,
        expectedFulfillmentDate: Date,
        prayerNote: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.uuid = uuid
        self.donorId = donorId
        self.campaignId = campaignId
        self.pledgeAmount = pledgeAmount
        self.status = status
        self.expectedFulfillmentDate = expectedFulfillmentDate
        self.prayerNote = prayerNote
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Validation Extension
extension Pledge {
    func validate() throws {
        if pledgeAmount <= 0 {
            throw PledgeValidationError.invalidAmount
        }
        if donorId == nil {
            throw PledgeValidationError.missingDonor
        }
        // Expected fulfillment date is non-optional in init, so always present.
        // Add other specific validations if necessary.
    }
}

// MARK: - Mock Data Generator (Optional, for previews and testing)
#if DEBUG
struct MockPledgeGenerator {
    static func generatePledge(id: Int, donorId: Int, campaignId: Int? = nil) -> Pledge {
        let statuses: [PledgeStatus] = [.pledged, .partiallyFulfilled, .fulfilled, .cancelled]
        
        return Pledge(
            id: id,
            donorId: donorId,
            campaignId: campaignId,
            pledgeAmount: Double.random(in: 10...1000),
            status: statuses.randomElement()!,
            expectedFulfillmentDate: Calendar.current.date(byAdding: .day, value: Int.random(in: 7...90), to: Date())!,
            prayerNote: Bool.random() ? "Pray for family health." : nil,
            notes: Bool.random() ? "Follow up in a month." : nil
        )
    }
    
    static func generatePledges(numberOfRecords: Int, startingDonorId: Int = 1) -> [Pledge] {
        guard numberOfRecords > 0 else { return [] }
        return (0..<numberOfRecords).map { index in
            generatePledge(id: index + 1, donorId: startingDonorId + index)
        }
    }

    static func singlePledge() -> Pledge {
        generatePledge(id: 1, donorId: 1)
    }
}
#endif