//
// DonationIncentive.swift
// TestDonorClass2
//
import Foundation
import GRDB

// MARK: - Validation Errors
enum DonationIncentiveValidationError: LocalizedError {
    case invalidName
    case invalidAmount
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Incentive name cannot be empty"
        case .invalidAmount:
            return "Dollar amount must be greater than zero"
        }
    }
}

// MARK: - Status Enum
enum DonationIncentiveStatus: String, Codable {
    case active
    case inactive
    case archived
}

// MARK: - DonationIncentive Model
struct DonationIncentive: Identifiable, Codable, FetchableRecord, PersistableRecord, Hashable {
    var id: Int?
    var uuid: String
    var name: String
    var description: String?
    var dollarAmount: Double
    var status: DonationIncentiveStatus
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "donation_incentive"
    
    // MARK: - Table Definition
    enum Columns {
        static let id = Column("id")
        static let uuid = Column("uuid")
        static let name = Column("name")
        static let description = Column("description")
        static let dollarAmount = Column("dollar_amount")
        static let status = Column("status")
        static let createdAt = Column("created_at")
        static let updatedAt = Column("updated_at")
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case name
        case description
        case dollarAmount = "dollar_amount"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Initialization
    init(uuid: String = UUID().uuidString,
         name: String,
         description: String? = nil,
         dollarAmount: Double,
         status: DonationIncentiveStatus = .active,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.uuid = uuid
        self.name = name
        self.description = description
        self.dollarAmount = dollarAmount
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Validation Extension
extension DonationIncentive {
    func validate() throws {
        if name.isEmpty {
            throw DonationIncentiveValidationError.invalidName
        }
        if dollarAmount <= 0 {
            throw DonationIncentiveValidationError.invalidAmount
        }
    }
}

