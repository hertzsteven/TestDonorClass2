import Foundation

/// Three fixed mock receipts the PoC view cycles through. Fixed (not
/// random) so the user can visually verify the data is changing on each
/// tap — and so a regression test can pin specific output later.
///
/// The labels "Receipt #: " and "Donation: " are baked into the strings
/// here because the template PDF does not pre-print those labels next to
/// the fields. The date field has no label by design.
enum ReceiptMockData {
    static let threeReceipts: [ReceiptFieldValues] = [
        ReceiptFieldValues(
            donorName: "Rabbi and Mrs. Chaim Werner",
            donorAddressBlock: "1442 45th St\nBrooklyn, NY 11219",
            receiptNumber: "Receipt #: A2 18993",
            receiptDate: "April 15, 2026",
            donationAmount: "Donation: $36.00"
        ),
        ReceiptFieldValues(
            donorName: "Mr. and Mrs. David Cohen",
            donorAddressBlock: "78 Ocean Parkway, Apt 4B\nBrooklyn, NY 11218",
            receiptNumber: "Receipt #: A2 19014",
            receiptDate: "April 22, 2026",
            donationAmount: "Donation: $108.00"
        ),
        ReceiptFieldValues(
            donorName: "Anonymous Friend",
            donorAddressBlock: "123 Main Street\nNew York, NY 10001",
            receiptNumber: "Receipt #: A2 19042",
            receiptDate: "April 28, 2026",
            donationAmount: "Donation: $1,800.00"
        ),
    ]
}
