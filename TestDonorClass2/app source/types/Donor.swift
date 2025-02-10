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
    var company: String?
    var salutation: String?
    var firstName: String?
    var lastName: String?
    var jewishName: String?
    var address: String?
    var addl_line: String?
    var suite: String?
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
        if let company = company {
            return "\(firstName ?? "")  \(lastName ?? "")\n\(company)"
        } else {
            return "\(firstName ?? "")  \(lastName ?? "")"
        }
    }
    var fullNameOld: String {
        "\(firstName ?? "")  \(lastName ?? "")  \(company ?? "")"
    }
    
    // MARK: - Table Definition
    enum Columns {
        static let id = Column("id")
        static let uuid = Column("uuid")
        static let company = Column("company")
        static let salutation = Column("salutation")
        static let firstName = Column("first_name")
        static let lastName = Column("last_name")
        static let jewishName = Column("jewish_name")
        static let address = Column("address")
        static let addl_line = Column("addl_line")
        static let suite = Column("suite")
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
        case id, uuid, company, salutation
        case firstName = "first_name"
        case lastName = "last_name"
        case jewishName = "jewish_name"
        case address, addl_line, suite ,city, state, zip, email, phone
        case donorSource = "donor_source"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Initialization
    init(// id: Int = 0,
        uuid: String = UUID().uuidString,
        company: String? = nil,
        salutation: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        jewishName: String? = nil,
        address: String? = nil,
        addl_line: String? = nil,
        suite: String? = nil,
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
            self.company = company
            self.firstName = firstName
            self.lastName = lastName
            self.jewishName = jewishName
            self.address = address
            self.addl_line = addl_line
            self.suite = suite
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

struct MockDonorGenerator {
    // Static helper function to generate random dates within a range
    static func randomDate(from startDate: Date = Date().addingTimeInterval(-365*24*60*60),
                         to endDate: Date = Date()) -> Date {
        let diff = endDate.timeIntervalSince(startDate)
        let randomDiff = Double.random(in: 0...diff)
        return startDate.addingTimeInterval(randomDiff)
    }
    
    // Static function to generate mock donors
    static func generateMockDonors() -> [Donor] {
        // Last names starting with "Bre"
        let breLastNames = ["Brennan", "Bremner", "Brewer", "Bresson", "Breckenridge"]
        // Last names starting with "Sta"
        let staLastNames = ["Stanley", "Stark", "Stanford", "Stanton", "Stafford"]
        // Other random last names
        let otherLastNames = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
                             "Rodriguez", "Martinez", "Anderson", "Taylor", "Thomas", "Moore", "Jackson",
                             "Martin", "Lee", "Thompson", "White", "Harris", "Clark", "Lewis", "Young",
                             "Walker", "Hall", "Allen", "King", "Wright", "Lopez", "Hill"]
        
        let firstNames = ["James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda",
                          "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica",
                          "Thomas", "Sarah", "Charles", "Karen", "Emma", "Olivia", "Noah", "Liam", "Sophia",
                          "Isabella", "Ava", "Mia", "Lucas", "Mason"]
        
        let companies = ["Tech Solutions Inc.", "Global Innovations", "Green Energy Co.", "Digital Dynamics",
                         "Future Systems", "Smart Solutions", "Eco Friendly Ltd.", "Modern Technologies",
                         "Cloud Computing Corp.", "Data Analytics Inc.", nil]
        
        let salutations = ["Mr.", "Mrs.", "Ms.", "Dr.", "Prof.", nil]
        
        let states = ["CA", "NY", "TX", "FL", "IL", "PA", "OH", "GA", "NC", "MI"]
        
        let cities = ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia",
                      "San Antonio", "San Diego", "Dallas", "San Jose"]
        
        var donors: [Donor] = []
        
        // Generate donors with "Bre" last names
        for lastName in breLastNames {
            let createdDate = randomDate()
            donors.append(Donor(
                uuid: UUID().uuidString,
                company: companies.randomElement()!,
                salutation: salutations.randomElement()!,
                firstName: firstNames.randomElement()!,
                lastName: lastName,
                address: "\(Int.random(in: 100...9999)) \(["Main", "Oak", "Maple", "Cedar", "Pine"].randomElement()!) St",
                city: cities.randomElement()!,
                state: states.randomElement()!,
                zip: String(format: "%05d", Int.random(in: 10000...99999)),
                email: "\(firstNames.randomElement()!.lowercased()).\(lastName.lowercased())@example.com",
                phone: String(format: "(%03d) %03d-%04d", Int.random(in: 200...999), Int.random(in: 200...999), Int.random(in: 0...9999)),
                notes: ["Prefers email", "Annual donor", "Corporate matching", "Volunteers regularly", nil].randomElement()!,
                createdAt: createdDate,
                updatedAt: createdDate.addingTimeInterval(Double.random(in: 0...7776000)) // Up to 90 days later
            ))
        }
        
        // Generate donors with "Sta" last names
        for lastName in staLastNames {
            let createdDate = randomDate()
            donors.append(Donor(
                uuid: UUID().uuidString,
                company: companies.randomElement()!,
                salutation: salutations.randomElement()!,
                firstName: firstNames.randomElement()!,
                lastName: lastName,
                address: "\(Int.random(in: 100...9999)) \(["Main", "Oak", "Maple", "Cedar", "Pine"].randomElement()!) St",
                city: cities.randomElement()!,
                state: states.randomElement()!,
                zip: String(format: "%05d", Int.random(in: 10000...99999)),
                email: "\(firstNames.randomElement()!.lowercased()).\(lastName.lowercased())@example.com",
                phone: String(format: "(%03d) %03d-%04d", Int.random(in: 200...999), Int.random(in: 200...999), Int.random(in: 0...9999)),
                notes: ["Prefers email", "Annual donor", "Corporate matching", "Volunteers regularly", nil].randomElement()!,
                createdAt: createdDate,
                updatedAt: createdDate.addingTimeInterval(Double.random(in: 0...7776000))
            ))
        }
        
        // Generate remaining random donors
        for _ in 1...(40 - breLastNames.count - staLastNames.count) {
            let createdDate = randomDate()
            donors.append(Donor(
                uuid: UUID().uuidString,
                company: companies.randomElement()!,
                salutation: salutations.randomElement()!,
                firstName: firstNames.randomElement()!,
                lastName: otherLastNames.randomElement()!,
                address: "\(Int.random(in: 100...9999)) \(["Main", "Oak", "Maple", "Cedar", "Pine"].randomElement()!) St",
                city: cities.randomElement()!,
                state: states.randomElement()!,
                zip: String(format: "%05d", Int.random(in: 10000...99999)),
                email: "\(firstNames.randomElement()!.lowercased()).\(otherLastNames.randomElement()!.lowercased())@example.com",
                phone: String(format: "(%03d) %03d-%04d", Int.random(in: 200...999), Int.random(in: 200...999), Int.random(in: 0...9999)),
                notes: ["Prefers email", "Annual donor", "Corporate matching", "Volunteers regularly", nil].randomElement()!,
                createdAt: createdDate,
                updatedAt: createdDate.addingTimeInterval(Double.random(in: 0...7776000))
            ))
        }
        
        return donors.shuffled() // Randomize the final order
    }
}
