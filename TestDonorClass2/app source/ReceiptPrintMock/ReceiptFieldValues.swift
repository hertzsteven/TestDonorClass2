import Foundation

/// Plain data carrier for the values that get stamped into the receipt
/// PDF's AcroForm fields. The keys (e.g. "donor_name") match the field
/// names baked into Chaye_Olam_Receipt.pdf.
///
/// Each property holds the *exact* string that should land in the PDF
/// field, including any label prefix (e.g. "Receipt #: ") that the PDF
/// itself does not pre-print as static text.
struct ReceiptFieldValues: Equatable, Sendable {
    var donorName: String = ""
    var donorAddressBlock: String = ""
    var receiptNumber: String = ""
    var receiptDate: String = ""
    var donationAmount: String = ""

    /// Maps a PDF field name (as stored in the template PDF) to the
    /// corresponding value held by this struct. Returns `nil` for any
    /// field name we don't recognise.
    func value(forFieldName name: String) -> String? {
        switch name {
        case "donor_name":          return donorName
        case "donor_address_block": return donorAddressBlock
        case "receipt_number":      return receiptNumber
        case "receipt_date":        return receiptDate
        case "donation_amount":     return donationAmount
        default:                    return nil
        }
    }
}
