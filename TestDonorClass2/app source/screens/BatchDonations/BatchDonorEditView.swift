import SwiftUI

struct BatchDonorEditView: View {
    @Binding var donor: Donor
    let onSave: (Donor) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var donorObject: DonorObjectClass

    @State private var showValidationError = false
    @State private var isPhoneValid = true
    @State private var isSaving = false

    // Form is valid if phone is valid AND (last name or company is filled)
    private var isFormValid: Bool {
        isPhoneValid && (!(donor.lastName?.isEmpty ?? true) || !(donor.company?.isEmpty ?? true))
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                personalInfoSection
                addressInfoSection
                contactInfoSection
                additionalInfoSection
            }
            .navigationTitle("Add New Donor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveAction) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
            // No more onAppear or setupInitialValues needed!
        }
    }

    // MARK: - Actions
    private func saveAction() {
        if isFormValid {
            Task {
                await saveDonor()
            }
        } else {
            // This will now correctly trigger validation summary
            showValidationError = true
            validateRequiredFields()
        }
    }

    // MARK: - Sections
    private var personalInfoSection: some View {
        Section(header: Text("Personal Information")) {
            TextField("Salutation", text: bind(\.salutation))
            TextField("First Name", text: bind(\.firstName))
            TextField("Last Name", text: bind(\.lastName))
                .onChange(of: donor.lastName) { _, _ in validateRequiredFields() }
            TextField("Jewish Name", text: bind(\.jewishName))
            TextField("Company", text: bind(\.company))
                .onChange(of: donor.company) { _, _ in validateRequiredFields() }

            if showValidationError && (donor.lastName?.isEmpty ?? true) && (donor.company?.isEmpty ?? true) {
                Text("Either Company or Last Name must be filled in.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var contactInfoSection: some View {
        Section(header: Text("Contact Information")) {
            TextField("Email", text: bind(\.email))
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            TextField("Phone", text: bind(\.phone))
                .keyboardType(.phonePad)
                .onChange(of: donor.phone) { _, newValue in
                    let formatted = formatPhoneNumber(newValue ?? "")
                    if formatted != (newValue ?? "") {
                        donor.phone = formatted
                    }
                    isPhoneValid = isValidPhone(formatted)
                }
                .foregroundColor(isPhoneValid ? .primary : .red)

            if !isPhoneValid {
                Text("Please enter a valid phone number.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var addressInfoSection: some View {
        Section(header: Text("Address")) {
            TextField("Street Address", text: bind(\.address))
            TextField("Additional Line", text: bind(\.addl_line))
            TextField("Apartment/Suite", text: bind(\.suite))
            TextField("City", text: bind(\.city))
            TextField("State", text: bind(\.state))
            TextField("ZIP", text: bind(\.zip))
                .keyboardType(.numberPad)
        }
    }

    private var additionalInfoSection: some View {
        Section(header: Text("Additional Information")) {
            TextEditor(text: bind(\.notes))
                .frame(height: 100)
        }
    }
    
    // MARK: - Helper Functions

    /// Creates a two-way binding for the donor's optional string properties.
    private func bind(_ keyPath: WritableKeyPath<Donor, String?>) -> Binding<String> {
        Binding(
            get: { self.donor[keyPath: keyPath] ?? "" },
            set: { self.donor[keyPath: keyPath] = $0.nillIfEmptyOrWhite }
        )
    }

    private func saveDonor() async {
        print("🔵 BatchDonorEditView: saveDonor() called")
        isSaving = true
        
        // No need to create a new object or update bindings.
        // The `donor` object is already up-to-date.
        print("🔵 BatchDonorEditView: About to save donor: \(donor.fullName)")

        do {
            // The `addDonor` function now correctly returns the saved donor with its ID
            let savedDonor = try await donorObject.addDonor(donor)
            
            await MainActor.run {
                isSaving = false
                // This `savedDonor` has the database ID and is passed back.
                onSave(savedDonor)
            }
        } catch {
            await MainActor.run {
                isSaving = false
                print("Error saving donor: \(error)")
                // TODO: Show an error alert to the user
            }
        }
    }

    private func validateRequiredFields() {
        showValidationError = (donor.lastName?.isEmpty ?? true) && (donor.company?.isEmpty ?? true)
    }

    // Phone validation and formatting (reused from DonorEditView)
    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = #"^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$"#
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phone.isEmpty || phonePredicate.evaluate(with: phone)
    }

    private func formatPhoneNumber(_ phoneNumber: String) -> String {
        let numbersOnly = phoneNumber.filter { "0123456789".contains($0) }
        let truncated = String(numbersOnly.prefix(10))

        var formatted = ""
        if truncated.count >= 7 {
            let areaCode = truncated.prefix(3)
            let prefix = truncated.dropFirst(3).prefix(3)
            let suffix = truncated.dropFirst(6)
            formatted = "(\(areaCode)) \(prefix)-\(suffix)"
        } else if truncated.count >= 4 {
            let areaCode = truncated.prefix(3)
            let prefix = truncated.dropFirst(3)
            formatted = "(\(areaCode)) \(prefix)"
        } else if !truncated.isEmpty {
            formatted = "(\(truncated)"
        }
        return formatted
    }
}

extension String {
    var nillIfEmptyOrWhite: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}