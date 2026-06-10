import SwiftUI

/// Read-only presentation of a donor's record, shown before the user
/// explicitly chooses to edit from the batch donation flow.
struct BatchDonorReadOnlyView: View {
    let donor: Donor

    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                LabeledContent("Salutation", value: donor.salutation ?? "—")
                LabeledContent("First Name", value: donor.firstName ?? "—")
                LabeledContent("Last Name", value: donor.lastName ?? "—")
                LabeledContent("Jewish Name", value: donor.jewishName ?? "—")
                LabeledContent("Company", value: donor.company ?? "—")
            }

            Section(header: Text("Address")) {
                LabeledContent("Street Address", value: donor.address ?? "—")
                LabeledContent("Additional Line", value: donor.addl_line ?? "—")
                LabeledContent("Apartment/Suite", value: donor.suite ?? "—")
                LabeledContent("City", value: donor.city ?? "—")
                LabeledContent("State", value: donor.state ?? "—")
                LabeledContent("ZIP", value: donor.zip ?? "—")
            }

            Section(header: Text("Contact Information")) {
                LabeledContent("Email", value: donor.email ?? "—")
                LabeledContent("Phone", value: donor.phone ?? "—")
            }

            if let notes = donor.notes, !notes.isEmpty {
                Section(header: Text("Additional Information")) {
                    Text(notes)
                }
            }
        }
    }
}
