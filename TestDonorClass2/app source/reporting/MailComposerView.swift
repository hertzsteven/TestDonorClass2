
import SwiftUI
import MessageUI

struct MailComposerView: UIViewControllerRepresentable {
    // MARK: - Properties
    let recipient: String
    let subject: String
    let body: String
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Init
    init(recipient: String, subject: String, body: String) {
        self.recipient = recipient
        self.subject = subject
        self.body = body
    }
    
    func makeCoordinator() -> Coordinator { 
        Coordinator(parent: self) 
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: true)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    // MARK: - Coordinator
    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposerView
        init(parent: MailComposerView) { 
            self.parent = parent 
        }
        
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true)
            parent.dismiss()
        }
    }
}

#Preview {
    MailComposerView(recipient: "test@example.com", subject: "Test", body: "Test body")
}
