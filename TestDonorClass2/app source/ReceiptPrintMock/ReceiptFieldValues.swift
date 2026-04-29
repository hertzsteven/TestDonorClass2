import Foundation

/// Plain data carrier for the values that get stamped into the receipt
/// PDF's AcroForm fields. The keys (e.g. "date_english") match the field
/// names baked into Tools/Receipt_Prototype.pdf.
struct ReceiptFieldValues: Equatable, Sendable {
    var dateEnglish: String = ""
    var dateHebrew: String = ""
    var greeting: String = ""
    var letterBody: String = ""
    var receiptDate: String = ""
    var receiptNumber: String = ""
    var receiptBody: String = ""
    var donorName: String = ""
    var donorStreet: String = ""
    var donorCityStateZip: String = ""

    /// Maps a PDF field name (as stored in the prototype PDF) to the
    /// corresponding value held by this struct. Returns `nil` for any
    /// field name we don't recognise.
    func value(forFieldName name: String) -> String? {
        switch name {
        case "date_english":         return dateEnglish
        case "date_hebrew":          return dateHebrew
        case "greeting":             return greeting
        case "letter_body":          return letterBody
        case "receipt_date":         return receiptDate
        case "receipt_number":       return receiptNumber
        case "receipt_body":         return receiptBody
        case "donor_name":           return donorName
        case "donor_street":         return donorStreet
        case "donor_city_state_zip": return donorCityStateZip
        default:                     return nil
        }
    }
}
