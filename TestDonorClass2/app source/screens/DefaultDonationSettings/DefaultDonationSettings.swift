import Foundation
import GRDB

struct DefaultDonationSettings: Codable, FetchableRecord, PersistableRecord {
    var id: Int?
    var amount: Double?
    var donationType: DonationType?
    var campaignId: Int?
    var donationIncentiveId: Int?
    var requestEmailReceipt: Bool
    var requestPrintedReceipt: Bool
    var notes: String?
    var isAnonymous: Bool
    
    // MARK: - Table Definition
    enum Columns {
        static let id = Column("id")
        static let amount = Column("amount")
        static let donationType = Column("donation_type")
        static let campaignId = Column("campaign_id")
        static let donationIncentiveId = Column("donation_incentive_id")
        static let requestEmailReceipt = Column("request_email_receipt")
        static let requestPrintedReceipt = Column("request_printed_receipt")
        static let notes = Column("notes")
        static let isAnonymous = Column("is_anonymous")
    }
    
    init(id: Int? = nil,
         amount: Double? = nil,
         donationType: DonationType? = nil,
         campaignId: Int? = nil,
         donationIncentiveId: Int? = nil,
         requestEmailReceipt: Bool = false,
         requestPrintedReceipt: Bool = false,
         notes: String? = nil,
         isAnonymous: Bool = false) {
        self.id = id
        self.amount = amount
        self.donationType = donationType
        self.campaignId = campaignId
        self.donationIncentiveId = donationIncentiveId
        self.requestEmailReceipt = requestEmailReceipt
        self.requestPrintedReceipt = requestPrintedReceipt
        self.notes = notes
        self.isAnonymous = isAnonymous
    }
    
    func applyToDonation(_ donation: inout Donation) {
        if let amount = amount { donation.amount = amount }
        if let donationType = donationType { donation.donationType = donationType }
        if let campaignId = campaignId { donation.campaignId = campaignId }
        if let donationIncentiveId = donationIncentiveId { donation.donationIncentiveId = donationIncentiveId }
        donation.requestEmailReceipt = requestEmailReceipt
        donation.requestPrintedReceipt = requestPrintedReceipt
        if let notes = notes { donation.notes = notes }
        donation.isAnonymous = isAnonymous
    }
}

// End of file. No additional code.
