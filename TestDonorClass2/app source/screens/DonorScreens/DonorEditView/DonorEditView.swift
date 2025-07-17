//
//  DonorEditView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/1/25.
//

import SwiftUI

// MARK: - Edit View
struct DonorEditView: View {
    
    let mode: Mode
    @Binding var donor: Donor
    
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var donorObject: DonorObjectClass

    
    @State private var company: String = ""
    @State private var salutation: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var jewishName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var addl_line: String = ""
    @State private var suite: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zip: String = ""
    @State private var notes: String = ""
    
    @State private var showValidationError = false
    
    private var isFormValid: Bool {
        isPhoneValid && (!lastName.isEmpty || !company.isEmpty)
    }
    
    @State private var isPhoneValid = true
    
    private var isAdd: Bool {
        if case .add = mode {
            return true
        }
        return false
    }

    var body: some View {
        NavigationView {
            Form {
                
                personalInfoSection
                
                addressInfoSection
                
                contactInfoSection
                
                additionalInfoSection
                
            }
            .navigationTitle(isAdd ? "Add New Donor" : "Edit Donor" )
            
            .toolbar { toolBarLeadLeftPane() }
            .toolbar { toolBarTrailLeftPane() }
            
            .onAppear {
                doOnAppearProcess()
            }
        }
    }
    

    private func saveTheDonor() async {
        
        switch mode {
        case .add:
            let thedonor = Donor(
                uuid:       donor.uuid,
                company:    company.nillIfEmptyOrWhite ,
                salutation: salutation.nillIfEmptyOrWhite ,
                firstName:  firstName.nillIfEmptyOrWhite,
                lastName:   lastName.nillIfEmptyOrWhite,
                jewishName: jewishName.nillIfEmptyOrWhite,
                address:    address.nillIfEmptyOrWhite ,
                addl_line:  addl_line.nillIfEmptyOrWhite ,
                suite:      suite.nillIfEmptyOrWhite ,
                city:       city.nillIfEmptyOrWhite ,
                state:      state.nillIfEmptyOrWhite ,
                zip:        zip.nillIfEmptyOrWhite ,
                email:      email.nillIfEmptyOrWhite ,
                phone:      phone.nillIfEmptyOrWhite ,
                notes:      notes.nillIfEmptyOrWhite
            )
            donor = thedonor
        case .edit(var existingDonor):
            existingDonor.company    = company.nillIfEmptyOrWhite
            existingDonor.salutation = salutation.nillIfEmptyOrWhite
            existingDonor.firstName  = firstName.nillIfEmptyOrWhite
            existingDonor.lastName   = lastName.nillIfEmptyOrWhite
            existingDonor.jewishName = jewishName.nillIfEmptyOrWhite
            existingDonor.email      = email.nillIfEmptyOrWhite
            existingDonor.phone      = phone.nillIfEmptyOrWhite
            existingDonor.address    = address.nillIfEmptyOrWhite
            existingDonor.addl_line  = addl_line.nillIfEmptyOrWhite
            existingDonor.suite      = suite.nillIfEmptyOrWhite
            existingDonor.city       = city.nillIfEmptyOrWhite
            existingDonor.state      = state.nillIfEmptyOrWhite
            existingDonor.zip        = zip.nillIfEmptyOrWhite
            existingDonor.notes      = notes.nillIfEmptyOrWhite
            donor                    = existingDonor
        }
        
//        if case .edit(var existingDonor) = mode {
//
//        } else {
//
//        }
        
        do {
            if isAdd {
                try await donorObject.addDonor(donor)
            } else {
                try await donorObject.updateDonor(donor)
            }
        } catch {
            // Handle specific error cases
            print("Error saving donor: \(error)")
        }
    }
}

// MARK: - Validations
extension DonorEditView {
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
    
    func validateitInput(_ val: String) {
        showValidationError = val.isEmptyOrWhitespace
    }
}

// MARK: - Life Cycle Methods
extension DonorEditView {
    
    fileprivate func doOnDisappearProcess() {
    }
    
    fileprivate func doOnAppearProcess() {
        setupLocalStateVariables()
    }
    
    func setupLocalStateVariables() {
        guard case .edit(_) = mode else {
            return
        }
        company = donor.company ?? ""
        salutation = donor.salutation ?? ""
        firstName = donor.firstName  ?? ""
        lastName = donor.lastName  ?? ""
        jewishName = donor.jewishName ?? ""
        email = donor.email ?? ""
        phone = formatPhoneNumber(donor.phone ?? "")
        address = donor.address ?? ""
        addl_line = donor.addl_line ?? ""
        suite = donor.suite ?? ""
        city = donor.city ?? ""
        state = donor.state ?? ""
        zip = donor.zip ?? ""
        notes = donor.notes ?? ""

        isPhoneValid = isValidPhone(phone)
    }
}

// MARK: - Screen Views
extension DonorEditView {
    
    private var personalInfoSection: some View {
        Section(header: Text("Personal Information")) {
            TextField("Salutation", text: $salutation)
            TextField("First Name", text: $firstName)

            TextField("Last Name", text: $lastName)
                .onChange(of: lastName, perform: validateitInput)
//                .onChange(of: lastName) { val in
//                    if val.isEmptyOrWhitespace {
//                        showValidationError = true
//                    } else {
//                        showValidationError = false
//                    }
//                }

            TextField("Jewish Name", text: $jewishName)
            TextField("Company", text: $company)
                .onChange(of: company, perform: validateitInput) 

            if showValidationError {
                Text("Either Company or Last Name must be filled in")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var contactInfoSection: some View {
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
    }
    
    private var addressInfoSection: some View {
        Section(header: Text("Address")) {
            TextField("Street Address", text: $address)
            TextField("Additional Line", text: $addl_line)
            TextField("Apartment/Suite", text: $suite)
            TextField("City", text: $city)
            TextField("State", text: $state)
            TextField("ZIP", text: $zip)
                .keyboardType(.numberPad)
        }
    }
    
    private var additionalInfoSection: some View {
        Section(header: Text("Additional Information")) {
            TextEditor(text: $notes)
                .frame(height: 100)
        }
    }
    
}

// MARK: - Toolbars
extension DonorEditView {
//    private var toolbarContent: some ToolbarContent {
//        ToolbarItem(placement: .navigationBarLeading) {
//            Button("Cancel") {
//                presentationMode.wrappedValue.dismiss()
//            }
//        }
//    
//        ToolbarItem(placement: .navigationBarTrailing) {
//            Button("Save") {
//                print("llll")
//            }
//            .disabled(true)
//        }
//    }
    
    
    @ToolbarContentBuilder
    func toolBarTrailLeftPane() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
                if isFormValid {
                    print("Save clicked")
                    Task {
                        await saveTheDonor()
                    }
                    dismiss()
                } else {
                    showValidationError = true
                }
            }
            .disabled(( company.isEmpty && lastName.isEmpty ) || !isPhoneValid)
        }
    }

    @ToolbarContentBuilder
    func toolBarLeadLeftPane() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
    }
}

// MARK: - Types
extension DonorEditView {
    enum Mode {
        case add
        case edit(Donor)
    }
    enum ValidationError: LocalizedError {
        case missingRequiredFields
        case invalidPhoneNumber
        
        var errorDescription: String? {
            switch self {
            case .missingRequiredFields:
                return "Either Company or Last Name must be filled in"
            case .invalidPhoneNumber:
                return "Please enter a valid phone number"
            }
        }
    }
}

// Existing code...

extension String {
    var isEmptyOrWhitespace: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
//    var nillIfEmptyOrWhite: String? {
//        return isEmptyOrWhitespace ? nil : self
//    }
}

//    // MARK: - Preview
//    #Preview {
//        Group {
////            // Preview Add Mode
////            NavigationView {
////                DonorEditView(mode: .add)
////                    .environmentObject(DonorObjectClass())
////            }
////            .previewDisplayName("Add Mode")
//            
//            // Preview Edit Mode with Sample Data
//            NavigationView {
//                DonorEditView(mode: .edit(Donor(
//                    uuid: "sample-id",
//                    salutation: "Mr.",
//                    firstName: "John",
//                    lastName: "Doe",
//                    jewishName: "Yaakov",
//                    address: "123 Main Street",
//                    city: "New York",
//                    state: "NY",
//                    zip: "10001",
//                    email: "john@example.com",
//                    phone: "(555) 123-4567",
//                    notes: "Sample donor for preview"
//                )))
//                .environmentObject(DonorObjectClass())
//            }
//            .previewDisplayName("Edit Mode")
//            
////            // Preview with Invalid Phone Number
////            NavigationView {
////                DonorEditView(mode: .edit(Donor(
////                    uuid: "sample-id-2",
////                    firstName: "Jane",
////                    lastName: "Smith",
////                    phone: "123" // Invalid phone number to demonstrate validation
////                )))
////                .environmentObject(DonorObjectClass())
////            }
////            .previewDisplayName("Invalid Phone")
//        }
//    }
