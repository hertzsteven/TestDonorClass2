//
//  Donation.swift
//  TestDonorClass2
//
//  Created by Steven Hertz
//

import Foundation
import GRDB

// MARK: - Donation Types
enum CampaignStatus: String, Codable {
    
    case draft = "DRAFT"
    case active = "ACTIVE"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
}

enum DonationType: String, Codable, CaseIterable {
    case creditCard = "CC"
    case check = "CHECK"
    case cash = "CASH"
    case other = "OTHER"
}

enum PaymentStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case completed = "COMPLETED"
    case failed = "FAILED"
}

enum ReceiptStatus: String, Codable, CaseIterable {
    case notRequested = "NOT_REQUESTED"
    case requested = "REQUESTED"
    case queued = "QUEUED"
    case printed = "PRINTED"
    case failed = "FAILED"
    
    var displayName: String {
        switch self {
        case .notRequested: return "Not Requested"
        case .requested: return "Requested"
        case .queued: return "Queued"
        case .printed: return "Printed"
        case .failed: return "Failed"
        }
    }
}

// MARK: - Validation Errors
enum DonationValidationError: LocalizedError {
    case invalidAmount
    case missingDonor
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Amount must be greater than zero"
        case .missingDonor:
            return "Donation must be associated with a donor"
        }
    }
}



// MARK: - Donation Model
struct Donation: Identifiable, Codable, FetchableRecord, PersistableRecord, Hashable {
    var id: Int?
    let uuid: String
    var donorId: Int?
    var campaignId: Int?
    var donationIncentiveId: Int?  // Add this field
    var amount: Double
    var donationType: DonationType
    var paymentStatus: PaymentStatus
    var transactionNumber: String?
    var receiptNumber: String?
    var paymentProcessorInfo: String?
    var requestEmailReceipt: Bool
    var requestPrintedReceipt: Bool
    var receiptStatus: ReceiptStatus
    var notes: String?
    var isAnonymous: Bool
    var donationDate: Date
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Table Definition
    enum Columns {
        static let id = Column("id")
        static let uuid = Column("uuid")
        static let donorId = Column("donor_id")
        static let campaignId = Column("campaign_id")
        static let donationIncentiveId = Column("donation_incentive_id")  // Add this column
        static let amount = Column("amount")
        static let donationType = Column("donation_type")
        static let paymentStatus = Column("payment_status")
        static let transactionNumber = Column("transaction_number")
        static let receiptNumber = Column("receipt_number")
        static let paymentProcessorInfo = Column("payment_processor_info")
        static let requestEmailReceipt = Column("request_email_receipt")
        static let requestPrintedReceipt = Column("request_printed_receipt")
        static let receiptStatus = Column("receipt_status")
        static let notes = Column("notes")
        static let isAnonymous = Column("is_anonymous")
        static let donationDate = Column("donation_date")
        static let createdAt = Column("created_at")
        static let updatedAt = Column("updated_at")
    }
    
    // MARK: - GRDB Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, uuid
        case donorId = "donor_id"
        case campaignId = "campaign_id"
        case donationIncentiveId = "donation_incentive_id"  // Add this case
        case amount
        case donationType = "donation_type"
        case paymentStatus = "payment_status"
        case transactionNumber = "transaction_number"
        case receiptNumber = "receipt_number"
        case paymentProcessorInfo = "payment_processor_info"
        case requestEmailReceipt = "request_email_receipt"
        case requestPrintedReceipt = "request_printed_receipt"
        case receiptStatus = "receipt_status"
        case notes
        case isAnonymous = "is_anonymous"
        case donationDate = "donation_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Initialization
    init(// id: Int? = nil,
         uuid: String = UUID().uuidString,
         donorId: Int? = nil,
         campaignId: Int? = nil,
         donationIncentiveId: Int? = nil,  // Add this parameter
         amount: Double,
         donationType: DonationType,
         paymentStatus: PaymentStatus = .pending,
         transactionNumber: String? = nil,
         receiptNumber: String? = nil,
         paymentProcessorInfo: String? = nil,
         requestEmailReceipt: Bool = false,
         requestPrintedReceipt: Bool = false,
         notes: String? = nil,
         isAnonymous: Bool = false,
         donationDate: Date = Date(),
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
//        self.id = id
        self.uuid = uuid
        self.donorId = donorId
        self.campaignId = campaignId
        self.donationIncentiveId = donationIncentiveId  // Add this assignment
        self.amount = amount
        self.donationType = donationType
        self.paymentStatus = paymentStatus
        self.transactionNumber = transactionNumber
        self.receiptNumber = receiptNumber
        self.paymentProcessorInfo = paymentProcessorInfo
        self.requestEmailReceipt = requestEmailReceipt
        self.requestPrintedReceipt = requestPrintedReceipt
        self.receiptStatus = requestPrintedReceipt ? .requested : .notRequested
        self.notes = notes
        self.isAnonymous = isAnonymous
        self.donationDate = donationDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}



// MARK: - Validation Extension
extension Donation {
    func validate() throws {
        if amount <= 0 {
            throw DonationValidationError.invalidAmount
        }
        if !isAnonymous && donorId == nil {
            throw DonationValidationError.missingDonor
        }
        // Add more validation as needed
    }
}
