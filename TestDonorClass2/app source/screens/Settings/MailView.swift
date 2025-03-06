    //
    //  EmailReceiptView.swift
    //  Donor Organization
    //
    //  Created by Steven Hertz on 11/28/24.
    //

    import SwiftUI
    import MessageUI


    struct MailView: UIViewControllerRepresentable {
        let receipt: OldReceipt
        var emailRecipient: String = ""
        var onCompletion: () -> Void

        func makeUIViewController(context: Context) -> UIViewController {
            guard MFMailComposeViewController.canSendMail() else {
                let alertController = UIAlertController(
                    title: "Email Not Available",
                    message: "Please set up email on your device and try again.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.onCompletion()
                })
                return alertController
            }
            
            let mailVC = MFMailComposeViewController()
            mailVC.mailComposeDelegate = context.coordinator
            mailVC.setToRecipients([emailRecipient])
            mailVC.setSubject("Donation Receipt")
            
            // Explicit debug logging
            let htmlBody = generateReceiptHTML()
            print("Generated HTML Body: \(htmlBody)")
            
            mailVC.setMessageBody(htmlBody, isHTML: true)
            return mailVC
        }
        
        private func generateReceiptHTML() -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            
            return """
            <html>
            <head>
                <style>
                    body { font-family: Arial, sans-serif; }
                    .header { text-align: center; margin-bottom: 20px; }
                    .details { margin: 20px 0; }
                    .total { font-weight: bold; font-size: 1.2em; }
                </style>
            </head>
            <body>
                <div class="header">
                    <h1>Donation Receipt</h1>
                    <p>Thank you for your generous donation!</p>
                </div>
                
                <div class="details">
                    <p>Date: \(dateFormatter.string(from: receipt.date))</p>
                    <p>Donor: \(receipt.donorName)</p>
                    <p>Donation Type: \(receipt.donationType)</p>
                </div>
                
                <table border="1" style="width: 100%; border-collapse: collapse;">
                    <tr>
                        <th>Description</th>
                        <th>Amount</th>
                    </tr>
                    \(receipt.items.map { item in
                        "<tr><td>\(item.name)</td><td align='right'>$\(String(format: "%.2f", item.price))</td></tr>"
                    }.joined())
                </table>
                
                <div class="total">
                    <p>Total Amount: $\(String(format: "%.2f", receipt.total))</p>
                </div>
                
                <div style="margin-top: 40px;">
                    <p><em>This receipt is for your tax records.</em></p>
                </div>
            </body>
            </html>
            """
        }
        

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
            var parent: MailView
            
            init(_ parent: MailView) {
                self.parent = parent
            }
            
            func mailComposeController(_ controller: MFMailComposeViewController,
                                       didFinishWith result: MFMailComposeResult,
                                       error: Error?) {
                controller.dismiss(animated: true)
                self.parent.onCompletion()
            }
        }
        
    }

    // Example Receipt models
    struct OldReceipt {
        let date: Date
        let total: Double
        let items: [OldReceiptItem]
        let donorName: String      // Add these new fields
        let donationType: String
    }


    struct OldReceiptItem {
        let name: String
        let price: Double
    }

