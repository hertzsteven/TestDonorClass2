//
//  ExternalDonationDecisionView.swift
//  TestDonorClass2
//

import SwiftUI

struct ExternalDonationDecisionView: View {
    let item: ExternalDonationItem
    /// Saves the decision without writing yet.
    let onDecide: (ExternalDonationDecision) -> Void
    /// Saves the decision and writes this one donation immediately.
    let onDecideAndApply: (ExternalDonationDecision) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [Donor] = []
    @State private var isSearching = false
    @State private var searchError: String?

    private let donorRepository: any DonorSpecificRepositoryProtocol

    init(
        item: ExternalDonationItem,
        donorRepository: any DonorSpecificRepositoryProtocol,
        onDecide: @escaping (ExternalDonationDecision) -> Void,
        onDecideAndApply: @escaping (ExternalDonationDecision) -> Void
    ) {
        self.item = item
        self.donorRepository = donorRepository
        self.onDecide = onDecide
        self.onDecideAndApply = onDecideAndApply
    }

    var body: some View {
        NavigationStack {
            Form {
                giftSection
                contactSection
                candidatesSection
                searchSection
                applyNowSection
                saveForLaterSection
            }
            .navigationTitle("One donation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var giftSection: some View {
        Section("Gift from file") {
            LabeledContent("Name", value: item.record.displayName)
            LabeledContent("Source", value: item.record.source.displayName)
            LabeledContent("Date") {
                Text(item.record.date, format: .dateTime.month().day().year())
            }
            LabeledContent("Amount") {
                Text(
                    item.record.amount,
                    format: .currency(code: "USD").precision(.fractionLength(2))
                )
            }
            if let reference = item.record.referenceNumber {
                LabeledContent("Reference", value: reference)
            }
            if let review = item.record.reviewNeeded {
                Text(review)
                    .foregroundStyle(Color.orange)
            }
            LabeledContent("Current decision", value: item.decision.shortLabel)
        }
    }

    private var contactSection: some View {
        Section("Contact on file") {
            if let email = item.record.email {
                LabeledContent("Email", value: email)
            }
            if !item.record.address.isEmpty {
                ForEach(item.record.address.displayLines, id: \.self) { line in
                    Text(line)
                }
            }
            if item.record.email == nil && item.record.address.isEmpty {
                Text("No email or postal address on this row.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var candidatesSection: some View {
        Section("Suggested donors") {
            if item.candidates.isEmpty {
                Text("No automatic matches.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(item.candidates) { candidate in
                    candidateButtons(for: .attach(donorId: candidate.id), title: candidate.displayName) {
                        VStack(alignment: .leading) {
                            Text(candidate.displayName)
                                .bold()
                                .foregroundStyle(Color.primary)
                            Text("\(candidate.reason.displayName) · ID \(candidate.id)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !candidate.donor.currentAddress.isEmpty {
                                Text(candidate.donor.currentAddress.displayLines.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var searchSection: some View {
        Section("Search donors") {
            HStack {
                TextField("Name or company", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Search") {
                    Task { await runSearch() }
                }
                .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 || isSearching)
            }

            if isSearching {
                ProgressView()
            }

            if let searchError {
                Text(searchError)
                    .foregroundStyle(Color.orange)
            }

            ForEach(searchResults) { donor in
                if let id = donor.id {
                    candidateButtons(for: .attach(donorId: id), title: displayName(for: donor)) {
                        VStack(alignment: .leading) {
                            Text(displayName(for: donor))
                                .bold()
                                .foregroundStyle(Color.primary)
                            Text("ID \(id)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var applyNowSection: some View {
        Section {
            if item.outcome == .likelyMatch || item.outcome == .forcedReview,
               let top = item.candidates.first {
                Button("Apply now · \(top.displayName)") {
                    applyNow(.attach(donorId: top.id))
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Apply now · Create as new donor") {
                applyNow(.createNew)
            }
            .buttonStyle(.borderedProminent)

            Button("Apply now · Anonymous / Unidentified") {
                applyNow(.anonymous)
            }
        } header: {
            Text("Apply this one donation")
        } footer: {
            Text("Writes only this row, then returns you to the list. Other rows are left alone.")
        }
    }

    private var saveForLaterSection: some View {
        Section("Or save decision for later") {
            if item.outcome == .likelyMatch || item.outcome == .forcedReview,
               let top = item.candidates.first {
                Button("Remember \(top.displayName)") {
                    saveOnly(.attach(donorId: top.id))
                }
            }

            Button("Remember: Create as new donor") {
                saveOnly(.createNew)
            }

            Button("Remember: Anonymous / Unidentified") {
                saveOnly(.anonymous)
            }

            Button("Skip this row", role: .destructive) {
                saveOnly(.skip)
            }
        }
    }

    @ViewBuilder
    private func candidateButtons<Label: View>(
        for decision: ExternalDonationDecision,
        title: String,
        @ViewBuilder label: () -> Label
    ) -> some View {
        VStack(alignment: .leading) {
            label()
            HStack {
                Button("Apply now") {
                    applyNow(decision)
                }
                .buttonStyle(.borderedProminent)

                Button("Remember") {
                    saveOnly(decision)
                }
                .buttonStyle(.bordered)
            }
            .accessibilityLabel(title)
        }
    }

    private func applyNow(_ decision: ExternalDonationDecision) {
        onDecideAndApply(decision)
        dismiss()
    }

    private func saveOnly(_ decision: ExternalDonationDecision) {
        onDecide(decision)
        dismiss()
    }

    private func runSearch() async {
        isSearching = true
        defer { isSearching = false }
        searchError = nil
        do {
            searchResults = try await donorRepository.findByName(searchText)
        } catch {
            searchError = error.localizedDescription
            searchResults = []
        }
    }

    private func displayName(for donor: Donor) -> String {
        let name = [donor.firstName, donor.lastName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        if let company = donor.company, !company.isEmpty {
            return name.isEmpty ? company : "\(name) (\(company))"
        }
        return name.isEmpty ? "Donor #\(donor.id ?? 0)" : name
    }
}
