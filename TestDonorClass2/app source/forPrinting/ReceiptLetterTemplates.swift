import Foundation

/// Greeting and body text for the receipt letter, with `{placeholder}` markers
/// substituted by `ReceiptFieldValuesBuilder` at print time.
struct ReceiptLetterTemplates: Equatable, Sendable {
    var greeting: String
    var body: String

    static let `default` = ReceiptLetterTemplates(
        greeting: ReceiptFieldValuesBuilder.defaultGreetingTemplate,
        body: ReceiptFieldValuesBuilder.defaultBodyTemplate
    )
}
