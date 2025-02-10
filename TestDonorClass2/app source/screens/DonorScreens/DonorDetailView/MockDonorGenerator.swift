//
//  DonationDonorsViewModel.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/9/25.
//


import Foundation

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




