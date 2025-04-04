struct PrayerNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    let donor: Donor?
    @Binding var prayerNote: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Display donor information
                if let donor = donor {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prayer Note for \(donor.fullName)")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Display additional donor information
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if let company = donor.company, !company.isEmpty {
                                    Text(company)
                                        .font(.subheadline)
                                }
                                if let address = donor.address, !address.isEmpty {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if let city = donor.city, let state = donor.state, let zip = donor.zip {
                                    Text("\(city), \(state) \(zip)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                } else {
                    Text("Prayer Note")
                        .font(.headline)
                }
                
                Text("Prayer Request:")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                
                TextEditor(text: $prayerNote)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Text("Enter any prayer requests or notes for this donor.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("Prayer Note", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
    }
}