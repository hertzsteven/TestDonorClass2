import Foundation

@Observable
class TempOrgSettings {
    var name: String
    var addressLine1: String
    var city: String
    var state: String
    var zip: String
    var ein: String
    var website: String
    var email: String
    var phone: String
    
    init(from info: OrganizationInfo) {
        self.name = info.name
        self.addressLine1 = info.addressLine1
        self.city = info.city
        self.state = info.state
        self.zip = info.zip
        self.ein = info.ein
        self.website = info.website ?? ""
        self.email = info.email ?? ""
        self.phone = info.phone ?? ""
    }
    
    func toOrgInfo() -> OrganizationInfo {
        OrganizationInfo(
            name: name,
            addressLine1: addressLine1,
            city: city,
            state: state,
            zip: zip,
            ein: ein,
            website: website.isEmpty ? nil : website,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone
        )
    }
}