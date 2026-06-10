//
//  ReceiptDetailSheetView.swift
//  TestDonorClass2
//
//  Presents the full database record behind a receipt row in a
//  grouped Form. Shown via long-press context menu from the
//  receipt list.
//

import SwiftUI

struct ReceiptDetailSheetView: View {
    let receiptItem: ReceiptItem
    let donationRepository: DonationRepository

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ReceiptDetailViewModel

    init(receiptItem: ReceiptItem, donationRepository: DonationRepository) {
        self.receiptItem = receiptItem
        self.donationRepository = donationRepository
        _viewModel = State(
            initialValue: ReceiptDetailViewModel(
                receiptItem: receiptItem,
                donationRepository: donationRepository
            )
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading details…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let donation = viewModel.donation {
                    detailForm(donation)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Could Not Load Details",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                }
            }
            .navigationTitle("Receipt Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Detail Form

    @ViewBuilder
    private func detailForm(_ donation: Donation) -> some View {
        Form {
            donorSection
            donationDetailsSection(donation)
            receiptInfoSection(donation)
            campaignSection
            transactionSection(donation)
            notesSection(donation)
            metadataSection(donation)
        }
    }

    // MARK: - Sections

    private var donorSection: some View {
        Section("Donor Information") {
            DetailRow(title: "Name", value: viewModel.donorDisplayName)

            if let company = viewModel.donorCompany {
                DetailRow(title: "Company", value: company)
            }

            if let address = viewModel.donorAddress {
                DetailRow(title: "Address", value: address)
            }

            if let phone = viewModel.donorPhone {
                DetailRow(title: "Phone", value: phone)
            }

            if let email = viewModel.donorEmail {
                DetailRow(title: "Email", value: email)
            }
        }
    }

    private func donationDetailsSection(_ donation: Donation) -> some View {
        Section("Donation Details") {
            HStack {
                Text("Amount")
                Spacer()
                Text(donation.amount, format: .currency(code: "USD"))
                    .foregroundStyle(.secondary)
            }

            DetailRow(
                title: "Donation Date",
                value: donation.donationDate.formatted(date: .abbreviated, time: .omitted)
            )

            DetailRow(title: "Donation Type", value: donation.donationType.displayName)

            DetailRow(title: "Payment Status", value: donation.paymentStatus.rawValue.capitalized)
        }
    }

    private func receiptInfoSection(_ donation: Donation) -> some View {
        Section("Receipt Information") {
            if let receiptNumber = donation.receiptNumber, !receiptNumber.isEmpty {
                DetailRow(title: "Receipt #", value: receiptNumber)
            }

            DetailRow(title: "Receipt Status", value: donation.receiptStatus.displayName)

            DetailRow(
                title: "Email Receipt",
                value: donation.requestEmailReceipt ? "Yes" : "No"
            )

            DetailRow(
                title: "Printed Receipt",
                value: donation.requestPrintedReceipt ? "Yes" : "No"
            )

            if let batchId = donation.printBatchId {
                DetailRow(title: "Print Batch", value: "#\(batchId)")
            }

            if let printedAt = donation.printedAt {
                DetailRow(
                    title: "Printed At",
                    value: printedAt.formatted(date: .abbreviated, time: .shortened)
                )
            }
        }
    }

    @ViewBuilder
    private var campaignSection: some View {
        if let campaignName = viewModel.campaignDisplayName {
            Section("Campaign") {
                DetailRow(title: "Campaign", value: campaignName)
            }
        }
    }

    @ViewBuilder
    private func transactionSection(_ donation: Donation) -> some View {
        if donation.transactionNumber != nil || donation.paymentProcessorInfo != nil {
            Section("Transaction") {
                if let txn = donation.transactionNumber, !txn.isEmpty {
                    DetailRow(title: "Transaction #", value: txn)
                }
                if let processorInfo = donation.paymentProcessorInfo, !processorInfo.isEmpty {
                    DetailRow(title: "Processor Info", value: processorInfo)
                }
            }
        }
    }

    @ViewBuilder
    private func notesSection(_ donation: Donation) -> some View {
        if let notes = donation.notes, !notes.isEmpty {
            Section("Notes") {
                Text(notes)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func metadataSection(_ donation: Donation) -> some View {
        Section("Record Info") {
            DetailRow(title: "Donation ID", value: "\(donation.id ?? 0)")

            DetailRow(
                title: "Created",
                value: donation.createdAt.formatted(date: .abbreviated, time: .shortened)
            )

            DetailRow(
                title: "Last Updated",
                value: donation.updatedAt.formatted(date: .abbreviated, time: .shortened)
            )
        }
    }
}
