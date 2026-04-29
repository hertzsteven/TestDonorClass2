import Foundation

/// Three fixed mock receipts the PoC view cycles through. Fixed (not
/// random) so the user can visually verify the data is changing on each
/// tap — and so a regression test can pin specific output later.
enum ReceiptMockData {
    static let threeReceipts: [ReceiptFieldValues] = [
        ReceiptFieldValues(
            dateEnglish: "April 15, 2026",
            dateHebrew: "28 Nisan 5786",
            greeting: "Dear Chaim and Yospa,",
            letterBody: """
                I want to express my heartfelt gratitude for your generous donation of $36.00. Your contribution is deeply appreciated and plays a crucial role in supporting Colel Chabad's mission to assist those in need in Israel.

                Your partnership makes a significant difference in their lives, providing them with hope and assistance during challenging times.

                May you be blessed abundantly for your kindness and generosity.
                """,
            receiptDate: "April 15, 2026",
            receiptNumber: "A2 18993",
            receiptBody: "We have gratefully received your generous donation of $36.00 in loving memory of Chaim Gedalya ben Yehoshua, OBM.",
            donorName: "Rabbi and Mrs. Chaim Werner",
            donorStreet: "1442 45th St",
            donorCityStateZip: "Brooklyn, NY 11219"
        ),
        ReceiptFieldValues(
            dateEnglish: "April 22, 2026",
            dateHebrew: "5 Iyar 5786",
            greeting: "Dear David and Sarah,",
            letterBody: """
                I want to express my heartfelt gratitude for your generous donation of $108.00. Your contribution is deeply appreciated and plays a crucial role in supporting our ongoing programs for families in need.

                May your kindness return to you many times over.
                """,
            receiptDate: "April 22, 2026",
            receiptNumber: "A2 19014",
            receiptBody: "We have gratefully received your generous donation of $108.00 for the speedy recovery of Yaakov ben Sara.",
            donorName: "Mr. and Mrs. David Cohen",
            donorStreet: "78 Ocean Parkway, Apt 4B",
            donorCityStateZip: "Brooklyn, NY 11218"
        ),
        ReceiptFieldValues(
            dateEnglish: "April 28, 2026",
            dateHebrew: "11 Iyar 5786",
            greeting: "Dear Anonymous Friend,",
            letterBody: """
                I want to express my heartfelt gratitude for your generous donation of $1,800.00. Your contribution makes a profound difference in supporting families across Israel during these challenging times.
                """,
            receiptDate: "April 28, 2026",
            receiptNumber: "A2 19042",
            receiptBody: "We have gratefully received your generous donation of $1,800.00 for the General Fund.",
            donorName: "Anonymous Friend",
            donorStreet: "123 Main Street",
            donorCityStateZip: "New York, NY 10001"
        ),
    ]
}
