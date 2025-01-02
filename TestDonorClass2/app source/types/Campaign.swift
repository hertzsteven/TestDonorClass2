//
//  Campaign.swift
//  fuller crud customer product
//
//  Created by Steven Hertz on 12/12/24.
//
import Foundation
import GRDB
// MARK: - Campaign Model
struct Campaign: Identifiable, Codable, FetchableRecord, PersistableRecord {
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
}
