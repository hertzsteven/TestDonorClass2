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
                    .disabled(firstName.isEmpty || lastName.isEmpty)
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
                    phone = donor.phone ?? ""
                    address = donor.address ?? ""
                    city = donor.city ?? ""
                    state = donor.state ?? ""
                    zip = donor.zip ?? ""
                    notes = donor.notes ?? ""
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
