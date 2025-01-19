//
//  Donor 2.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 12/24/24.
//


import Foundation
import GRDB

// MARK: - Donor Model
struct Donor: Identifiable, Codable, Hashable, FetchableRecord, PersistableRecord {
    var id: Int?
    let uuid: String
    var salutation: String?
    var firstName: String?
    var lastName: String?
    var jewishName: String?
    var address: String?
    var city: String?
    var state: String?
    var zip: String?
    var email: String?
    var phone: String?
    var donorSource: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Properties
    var fullName: String {
        "\(firstName ?? "")  \(lastName ?? "")"
    }
    
    // MARK: - Table Definition
    enum Columns {
        static let id = Column("id")
        static let uuid = Column("uuid")
        static let salutation = Column("salutation")
        static let firstName = Column("first_name")
        static let lastName = Column("last_name")
        static let jewishName = Column("jewish_name")
        static let address = Column("address")
        static let city = Column("city")
        static let state = Column("state")
        static let zip = Column("zip")
        static let email = Column("email")
        static let phone = Column("phone")
        static let donorSource = Column("donor_source")
        static let notes = Column("notes")
        static let createdAt = Column("created_at")
        static let updatedAt = Column("updated_at")
    }

    // MARK: - GRDB Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, uuid, salutation
        case firstName = "first_name"
        case lastName = "last_name"
        case jewishName = "jewish_name"
        case address, city, state, zip, email, phone
        case donorSource = "donor_source"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Initialization
    init(// id: Int = 0,
         uuid: String = UUID().uuidString,
         salutation: String? = nil,
         firstName: String? = nil,
         lastName: String? = nil,
         jewishName: String? = nil,
         address: String? = nil,
         city: String? = nil,
         state: String? = nil,
         zip: String? = nil,
         email: String? = nil,
         phone: String? = nil,
         donorSource: String? = nil,
         notes: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
//        self.id = id
        self.uuid = uuid
        self.salutation = salutation
        self.firstName = firstName
        self.lastName = lastName
        self.jewishName = jewishName
        self.address = address
        self.city = city
        self.state = state
        self.zip = zip
        self.email = email
        self.phone = phone
        self.donorSource = donorSource
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Validation Extension
extension Donor {
    func validate() throws {
        if ((firstName?.isEmpty) != nil) {
            throw ValidationError.emptyFirstName
        }
        if ((lastName?.isEmpty) != nil) {
            throw ValidationError.emptyLastName
        }
        if let email = email, !email.isEmpty {
            // Basic email validation
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: email) {
                throw ValidationError.invalidEmail
            }
        }
    }
}

// MARK: - Error Types
enum ValidationError: LocalizedError {
    case emptyFirstName
    case emptyLastName
    case invalidEmail
    
    var errorDescription: String? {
        switch self {
        case .emptyFirstName:
            return "First name cannot be empty"
        case .emptyLastName:
            return "Last name cannot be empty"
        case .invalidEmail:
            return "Invalid email format"
        }
    }
}
