import SwiftUI
import MessageUI

/// Simple picker for email templates (mock data)
struct EmailTemplatePickerView: View {
    // MARK: - Template
    struct Template: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let subtitle: String
        let bodyPreview: String
    }

    // MARK: - Properties
    let templates: [Template]
    let onSelect: (Template) -> Void
    let firstReortItem: DonationReportItem
    @State private var showingMailComposer = false
    @State private var selectedTemplate: Template?
    @State private var showingAlert = false

    // MARK: - Init
    init(templates: [Template] = EmailTemplatePickerView.mockTemplates,
         reportItem: DonationReportItem,
         onSelect: @escaping (Template) -> Void) {
        self.templates = templates
        self.onSelect = onSelect
        self.firstReortItem = reportItem
    }

    // MARK: - Body
    var body: some View {
        List(templates) { template in
            Button {
                selectedTemplate = template
                if firstReortItem.email != nil {
                    showingMailComposer = true
                } else {
                    showingAlert = true
                }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.headline)
                    Text(template.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(template.bodyPreview)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Choose Template")
        .alert("No Email Available", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This donor does not have an email address.")
        }
        .sheet(isPresented: $showingMailComposer) {
            if let template = selectedTemplate,
               let email = firstReortItem.email {
                // Replace placeholder values with actual data
                let processedBody = template.bodyPreview
                    .replacingOccurrences(of: "{{name}}", with: firstReortItem.donorName)
                    .replacingOccurrences(of: "{{amount}}", with: String(format: "$%.2f", firstReortItem.amount))
                
                MailComposerView(
                    recipient: email,
                    subject: template.title,
                    body: processedBody
                )
            }
        }
    }
}

// MARK: - Mock Data
extension EmailTemplatePickerView {
    static let mockTemplates: [Template] = [
        .init(title: "Thank You",
              subtitle: "Send appreciation to recent donors",
              bodyPreview: "Dear {{name}},\n\nThank you so much for your generous donation of {{amount}}…"),
        .init(title: "We Miss You",
              subtitle: "Check-in with inactive donors",
              bodyPreview: "Hi {{name}},\n\nWe noticed we haven’t heard from you this year and wanted to share…"),
        .init(title: "Campaign Update",
              subtitle: "Progress report for active campaign",
              bodyPreview: "Greetings {{name}},\n\nWe’re excited to let you know that our campaign has reached 80%…")
    ]
}
