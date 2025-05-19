import Foundation

// Ensure this file is in a location where it can access the Donor model.
// Usually, alongside or near other model definitions or in a dedicated "Mocks" or "Testing" group/folder.

//struct MockDonorGenerator {
//
//    static func generateDonor(id: Int) -> Donor {
//        let firstNames = ["John", "Jane", "Alex", "Emily", "Michael", "Sarah", "David", "Laura", "Chris", "Pat"]
//        let lastNames = ["Smith", "Doe", "Johnson", "Williams", "Brown", "Davis", "Miller", "Wilson", "Taylor", "Clark"]
//        let companies = ["Alpha Tech", "Beta Solutions", "Gamma Inc.", "Delta Corp.", "Epsilon LLC", nil, "Innovate Co.", "Future Systems"]
//        let emails = ["john.doe@example.com", "jane.smith@example.net", "alex.j@example.org", nil, "emily.w@example.com", "m.brown@example.net"]
//        let phoneNumbers = ["555-0101", "555-0102", "555-0103", nil, "555-0104", "555-0105"]
//        let addresses = ["101 Maple St", "202 Oak Ave", "303 Pine Ln", "404 Cedar Rd", nil, "505 Birch Dr"]
//        let cities = ["Springfield", "Riverside", "Fairview", "Centerville", "Shelbyville", "Oakland"]
//        let states = ["CA", "NY", "TX", "FL", "IL", "WA"]
//        let zips = ["90210", "10001", "75001", "33101", "60601", "98101"]
//        let sources = ["Event A", "Online Campaign", "Referral Program", "Walk-in", "Gala Dinner"]
//        let notes = ["VIP Donor", "Met at 2023 conference", "Interested in children's programs", nil, "Long-time supporter", "Prefers email contact"]
//
//        let randomFirstName = firstNames.randomElement() ?? "FirstName"
//        let randomLastName = lastNames.randomElement() ?? "LastName"
//        let randomCompany = companies.randomElement() ?? nil
//        let randomEmail = emails.randomElement() ?? nil
//        let randomPhone = phoneNumbers.randomElement() ?? nil
//        let randomAddress = addresses.randomElement() ?? nil
//        let randomCity = cities.randomElement() ?? "Anytown"
//        let randomState = states.randomElement() ?? "AS" // AnyState
//        let randomZip = zips.randomElement() ?? "00000"
//        
//        let uuidString = UUID().uuidString
//
//        return Donor(
//            id: id,
//            uuid: uuidString,
//            firstName: randomFirstName,
//            lastName: randomLastName,
//            salutation: ["Mr.", "Ms.", "Dr.", "Prof.", "Mx."].randomElement(),
//            jewishName: ["Chaim", "Rivka", "Yosef", "Esther", "Shlomo"].randomElement(),
//            company: randomCompany,
//            address: randomAddress,
//            address2: Bool.random() ? "Apt \(Int.random(in: 1...100))" : nil,
//            city: randomCity,
//            state: randomState,
//            zip: randomZip,
//            country: "USA",
//            email: randomEmail,
//            phone: randomPhone,
//            donorSource: sources.randomElement(),
//            notes: notes.randomElement(),
//            createdAt: Date().addingTimeInterval(TimeInterval.random(in: -31536000...0)), // Randomly in the last year
//            updatedAt: Date().addingTimeInterval(TimeInterval.random(in: -86400...0))     // Randomly in the last day
//        )
//    }
//
//    static func generateDonors(numberOfRecords: Int) -> [Donor] {
//        guard numberOfRecords > 0 else { return [] }
//        // Ensure unique IDs for the generated set
//        let startId = (Int.random(in: 1...1000) * 100) // Start IDs higher to avoid collisions if mixed with real data
//        return (0..<numberOfRecords).map { generateDonor(id: startId + $0 + 1) }
//    }
//    
//    static func generateSingleDonor(id: Int = Int.random(in: 1...10000)) -> Donor {
//        return generateDonor(id: id)
//    }
//}
