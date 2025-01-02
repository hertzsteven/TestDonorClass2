//
//  DonorEditView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/1/25.
//

import SwiftUI
// MARK: - Edit View
struct DonorEditView: View {
    enum Mode {
        case add
//        case isAdd
        case edit(Donor)
    }
    
    let mode: Mode
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var donorObject: DonorObjectClass
    
    @State private var salutation: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var jewishName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zip: String = ""
    @State private var notes: String = ""
    
        // Add validation state
        @State private var isPhoneValid = true

        // Add phone validation function
        private func isValidPhone(_ phone: String) -> Bool {
            let phoneRegex = #"^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$"#
            let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
            return phone.isEmpty || phonePredicate.evaluate(with: phone)
        }
    
        // Add phone formatting function
        private func formatPhoneNumber(_ phoneNumber: String) -> String {
            // Remove all non-numeric characters
            let numbersOnly = phoneNumber.filter { "0123456789".contains($0) }
            // Limit to 10 digits
            let truncated = String(numbersOnly.prefix(10))
            
            // Format based on number length
            var formatted = ""
            if truncated.count > 6 {
                let areaCode = truncated.prefix(3)
                let prefix = truncated[truncated.index(truncated.startIndex, offsetBy: 3)..<truncated.index(truncated.startIndex, offsetBy: 6)]
                let remaining = truncated[truncated.index(truncated.startIndex, offsetBy: 6)...]
                formatted = "(\(areaCode)) \(prefix)-\(remaining)"
            } else if truncated.count > 3 {
                let areaCode = truncated.prefix(3)
                let remaining = truncated[truncated.index(truncated.startIndex, offsetBy: 3)...]
                formatted = "(\(areaCode)) \(remaining)"
            } else {
                formatted = truncated.isEmpty ? "" : "(\(truncated)"
            }
            
            return formatted
        }

    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Salutation", text: $salutation)
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Jewish Name", text: $jewishName)
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                        // Update phone formatting
                        .onChange(of: phone) { newValue in
                            let formatted = formatPhoneNumber(newValue)
                            if formatted != newValue {
                                phone = formatted
                            }
                            isPhoneValid = isValidPhone(formatted)
                        }
                        .foregroundColor(isPhoneValid ? .primary : .red)
                    if !isPhoneValid {
                        Text("Please enter a valid phone number")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Address")) {
                    TextField("Street Address", text: $address)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP", text: $zip)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Additional Information")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Edit Donor")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                        // Update save button disabled condition
                    .disabled(firstName.isEmpty || lastName.isEmpty || !isPhoneValid)
                }
            }
            .onAppear {
                if case .edit(let donor) = mode {
                    // Populate fields with existing donor data
                    salutation = donor.salutation ?? ""
                    firstName = donor.firstName
                    lastName = donor.lastName
                    jewishName = donor.jewishName ?? ""
                    email = donor.email ?? ""
                    phone = formatPhoneNumber(donor.phone ?? "")
                    address = donor.address ?? ""
                    city = donor.city ?? ""
                    state = donor.state ?? ""
                    zip = donor.zip ?? ""
                    notes = donor.notes ?? ""
                        // Validate phone on load
                    isPhoneValid = isValidPhone(phone)

                }
            }
        }
    }
    
    private var isAdd: Bool {
        if case .add = mode {
            return true
        }
        return false
    }
    
    private func save() {
        let donor: Donor
        if case .edit(var existingDonor) = mode {
            // Update existing donor
            existingDonor.salutation = salutation.isEmpty ? nil : salutation
            existingDonor.firstName = firstName
            existingDonor.lastName = lastName
            existingDonor.jewishName = jewishName.isEmpty ? nil : jewishName
            existingDonor.email = email.isEmpty ? nil : email
            existingDonor.phone = phone.isEmpty ? nil : phone
            existingDonor.address = address.isEmpty ? nil : address
            existingDonor.city = city.isEmpty ? nil : city
            existingDonor.state = state.isEmpty ? nil : state
            existingDonor.zip = zip.isEmpty ? nil : zip
            existingDonor.notes = notes.isEmpty ? nil : notes
            donor = existingDonor
        } else {
            // Create new donor
            donor = Donor(
                uuid: UUID().uuidString,
                salutation: salutation.isEmpty ? nil : salutation,
                firstName: firstName,
                lastName: lastName,
                jewishName: jewishName.isEmpty ? nil : jewishName,
                address: address.isEmpty ? nil : address,
                city: city.isEmpty ? nil : city,
                state: state.isEmpty ? nil : state,
                zip: zip.isEmpty ? nil : zip,
                email: email.isEmpty ? nil : email,
                phone: phone.isEmpty ? nil : phone,
                notes: notes.isEmpty ? nil : notes
            )
        }
        
        Task {
            do {
                if isAdd {
                    try await donorObject.addDonor(donor)
                } else {
                    try await donorObject.updateDonor(donor)
                }
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                // Handle error if needed
            }
        }
    }
}
    // MARK: - Preview
    #Preview {
        Group {
//            // Preview Add Mode
//            NavigationView {
//                DonorEditView(mode: .add)
//                    .environmentObject(DonorObjectClass())
//            }
//            .previewDisplayName("Add Mode")
            
            // Preview Edit Mode with Sample Data
            NavigationView {
                DonorEditView(mode: .edit(Donor(
                    uuid: "sample-id",
                    salutation: "Mr.",
                    firstName: "John",
                    lastName: "Doe",
                    jewishName: "Yaakov",
                    address: "123 Main Street",
                    city: "New York",
                    state: "NY",
                    zip: "10001",
                    email: "john@example.com",
                    phone: "(555) 123-4567",
                    notes: "Sample donor for preview"
                )))
                .environmentObject(DonorObjectClass())
            }
            .previewDisplayName("Edit Mode")
            
//            // Preview with Invalid Phone Number
//            NavigationView {
//                DonorEditView(mode: .edit(Donor(
//                    uuid: "sample-id-2",
//                    firstName: "Jane",
//                    lastName: "Smith",
//                    phone: "123" // Invalid phone number to demonstrate validation
//                )))
//                .environmentObject(DonorObjectClass())
//            }
//            .previewDisplayName("Invalid Phone")
        }
    }
