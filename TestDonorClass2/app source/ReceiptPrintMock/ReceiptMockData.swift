import Foundation

/// Three fixed mock receipts the PoC view cycles through. Fixed (not
/// random) so the user can visually verify the data is changing on each
/// tap — and so a regression test can pin specific output later.
///
/// The labels "Receipt #: " and "Donation: " are baked into the strings
/// here because the template PDF does not pre-print those labels next to
/// the fields. The letter date and receipt date have no label by design.
enum ReceiptMockData {
    static let threeReceipts: [ReceiptFieldValues] = [
        ReceiptFieldValues(
            letterDate: "April 15, 2026",
            letterGreeting: "Dear Chaim and Yospa,",
            letterBody: """
                I want to express my heartfelt gratitude for your generous donation of $36.00. Your contribution is deeply appreciated and plays a crucial role in supporting our mission to assist those in need.

                Your partnership makes a significant difference in their lives, providing them with hope and assistance during challenging times.

                May you be blessed abundantly for your kindness and generosity.
                """,
            donorName: "Rabbi and Mrs. Chaim Werner",
            donorAddressBlock: "1442 45th St\nBrooklyn, NY 11219",
            receiptNumber: "Receipt #: A2 18993",
            receiptDate: "April 15, 2026",
            donationAmount: "Donation: $36.00"
        ),
        ReceiptFieldValues(
            letterDate: "April 22, 2026",
            letterGreeting: "Dear David and Sarah,",
            letterBody: """
                I want to express my heartfelt gratitude for your generous donation of $108.00. Your contribution is deeply appreciated and plays a crucial role in supporting our ongoing programs for families in need.

                May your kindness return to you many times over.
                """,
            donorName: "Mr. and Mrs. David Cohen",
            donorAddressBlock: "78 Ocean Parkway, Apt 4B\nBrooklyn, NY 11218",
            receiptNumber: "Receipt #: A2 19014",
            receiptDate: "April 22, 2026",
            donationAmount: "Donation: $108.00"
        ),
        ReceiptFieldValues(
            letterDate: "April 28, 2026",
            letterGreeting: "Dear Anonymous Friend,",
            letterBody: """
                I want to express my heartfelt gratitude for your generous donation of $1,800.00. Your contribution makes a profound difference in supporting families during these challenging times.
                """,
            donorName: "Anonymous Friend",
            donorAddressBlock: "123 Main Street\nNew York, NY 10001",
            receiptNumber: "Receipt #: A2 19042",
            receiptDate: "April 28, 2026",
            donationAmount: "Donation: $1,800.00"
        ),
    ]
}
