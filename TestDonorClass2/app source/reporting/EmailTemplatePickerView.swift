
import SwiftUI

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

    // MARK: - Init
    init(templates: [Template] = EmailTemplatePickerView.mockTemplates,
         onSelect: @escaping (Template) -> Void) {
        self.templates = templates
        self.onSelect = onSelect
    }

    // MARK: - Body
    var body: some View {
        List(templates) { template in
            Button {
                onSelect(template)
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

// MARK: - Preview
#Preview {
    NavigationStack {
        EmailTemplatePickerView { _ in }
    }
}
