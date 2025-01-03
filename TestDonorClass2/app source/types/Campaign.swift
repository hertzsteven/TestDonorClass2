    //
    //  Campaign.swift
    //  fuller crud customer product
    //
    //  Created by Steven Hertz on 12/12/24.
    //
    import Foundation
    import GRDB

    // MARK: - Validation Errors
    enum CampaignValidationError: LocalizedError {
        case invalidName
        case invalidDates
        case invalidGoal
        
        var errorDescription: String? {
            switch self {
            case .invalidName:
                return "Campaign name cannot be empty"
            case .invalidDates:
                return "End date must be after start date"
            case .invalidGoal:
                return "Goal amount must be greater than zero"
            }
        }
    }

    // MARK: - Campaign Model
    struct Campaign: Identifiable, Codable, FetchableRecord, PersistableRecord, Hashable {
        var id: Int?
        var uuid: String
        var campaignCode: String
        var name: String
        var description: String?
        var startDate: Date?
        var endDate: Date?
        var status: CampaignStatus
        var goal: Double?
        var createdAt: Date
        var updatedAt: Date
        static let databaseTableName = "campaign"
        
        // MARK: - Table Definition
        enum Columns {
            static let id = Column("id")
            static let uuid = Column("uuid")
            static let campaignCode = Column("campaign_code")
            static let name = Column("name")
            static let description = Column("description")
            static let startDate = Column("start_date")
            static let endDate = Column("end_date")
            static let status = Column("status")
            static let goal = Column("goal")
            static let createdAt = Column("created_at")
            static let updatedAt = Column("updated_at")
        }
        
        private enum CodingKeys: String, CodingKey {
            case id
            case uuid
            case campaignCode = "campaign_code"
            case name
            case description
            case startDate = "start_date"
            case endDate = "end_date"
            case status
            case goal
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
        
        // MARK: - Initialization
        init(// id: Int? = nil,
             uuid: String = UUID().uuidString,
             campaignCode: String,
             name: String,
             description: String? = nil,
             startDate: Date? = nil,
             endDate: Date? = nil,
             status: CampaignStatus = .draft,
             goal: Double? = nil,
             createdAt: Date = Date(),
             updatedAt: Date = Date()) {
//            self.id = id
            self.uuid = uuid
            self.campaignCode = campaignCode
            self.name = name
            self.description = description
            self.startDate = startDate
            self.endDate = endDate
            self.status = status
            self.goal = goal
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    // MARK: - Validation Extension
    extension Campaign {
        func validate() throws {
            if name.isEmpty {
                throw CampaignValidationError.invalidName
            }
            if let start = startDate, let end = endDate, end <= start {
                throw CampaignValidationError.invalidDates
            }
            if let goalAmount = goal, goalAmount <= 0 {
                throw CampaignValidationError.invalidGoal
            }
            // Add more validation as needed
        }
    }
