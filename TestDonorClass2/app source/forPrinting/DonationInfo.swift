//
//  DonationInfo.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 2/6/25.
//

//
//  GeneratesaformattedreceiptFunc.swift
//  UseNSAttribute
//
//  Created by Steven Hertz on 2/5/25.
//

import Foundation
import UIKit

/// A simple model to hold donation details.
struct DonationInfo {
    let donorName: String
    let donationAmount: Double
    let date: String
}

final class ReceiptPrintingService {
    
    private let organizationProvider: OrganizationProvider
    // Add static reference to maintain print controller across instances
    private static var activePrintController: UIPrintInteractionController?

    /// Dependency injection of the organization provider.
    init(organizationProvider: OrganizationProvider = DefaultOrganizationProvider()) {
        self.organizationProvider = organizationProvider
    }

    /// Public method to print a receipt based on the donation information.
    func printReceipt(for donation: DonationInfo, completion: @escaping () -> Void) {
        print("Starting to print receipt in ReceiptPrintingService for \(donation.donorName)")
        guard let pdfURL = createReceiptPDF(for: donation) else {
            print("Error: Failed to generate receipt PDF.")
            return
        }
        
        DispatchQueue.main.async {
            // Store in static property to ensure it stays alive across the app
            ReceiptPrintingService.activePrintController = UIPrintInteractionController.shared
            ReceiptPrintingService.activePrintController?.printingItem = pdfURL
            
            print("About to present print controller")
            ReceiptPrintingService.activePrintController?.present(animated: true) { (controller, completed, error) in
                print("Print controller dismissed, completed: \(completed), error: \(String(describing: error))")
                // This will run after user either prints or cancels
                completion()
                // Clear the static reference after completion
                DispatchQueue.main.async {
                    ReceiptPrintingService.activePrintController = nil
                }
            }
        }
    }

    /// ✅ Generates a formatted receipt PDF using `NSAttributedString`
//    func createReceiptPDF(donorName: String, donationAmount: Double, date: String) -> URL? {
    private func createReceiptPDF(for donation: DonationInfo) -> URL? {
        let pageSize = CGSize(width: 612, height: 792) // 8.5" x 11"
        let pdfFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("receipt.pdf")
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        do {
            try renderer.writePDF(to: pdfFilePath, withActions: { context in
                context.beginPage()
                
                let margin: CGFloat = 50
                var yOffset: CGFloat = 50
                let paragraphSpacing: CGFloat = 20
                let fontSize: CGFloat = 12
                let font = UIFont.systemFont(ofSize: fontSize)
                
                // 🖼 Draw the header image (if available)
                if let headerImage = UIImage(named: "header") {
                    let imageWidth: CGFloat = 75
                    let imageHeight: CGFloat = 75
                    let imageX = pageSize.width - margin - imageWidth // Position image on the right
                    let textStartX = margin // Keep text on the left
                    
                    // Position image on the right
                    let imageRect = CGRect(x: imageX, y: yOffset, width: imageWidth, height: imageHeight)
                    headerImage.draw(in: imageRect)
                    
                    // Get the organization information from the injected provider.
                    // 🏷 Organization Header (placed to the left of the image)
                    let organizationText = organizationProvider.organizationInfo.formattedInfo

                    let orgAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: fontSize),
                        .paragraphStyle: leftAlignedParagraphStyle()
                    ]
                    let orgRect = CGRect(x: textStartX, y: yOffset, width: imageX - textStartX - 10, height: 60)
                    organizationText.draw(in: orgRect, withAttributes: orgAttributes)
                    
                    yOffset += max(imageHeight, 60) + paragraphSpacing // Move down based on tallest element
                }
                
                // 🔹 Receipt Title
                let title = "Donation Receipt"
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .paragraphStyle: centeredParagraphStyle()
                ]
                let titleRect = CGRect(x: margin, y: yOffset, width: pageSize.width - 2 * margin, height: 30)
                title.draw(in: titleRect, withAttributes: titleAttributes)
                yOffset += 40 + paragraphSpacing
                
                // 🔹 Receipt Information
                let receiptDetails = NSMutableAttributedString(string: "Receipt Details\n", attributes: [
                    .font: UIFont.boldSystemFont(ofSize: fontSize),
                    .paragraphStyle: leftAlignedParagraphStyle()
                ])
                
                let details = """
                Donor Name: \(donation.donorName)
                Donation Amount: $\(String(format: "%.2f", donation.donationAmount))
                Date: \(donation.date)
                """
                let detailsAttributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .paragraphStyle: leftAlignedParagraphStyle()
                ]
                receiptDetails.append(NSAttributedString(string: details, attributes: detailsAttributes))
                
                let receiptRect = CGRect(x: margin, y: yOffset, width: pageSize.width - 2 * margin, height: 80)
                receiptDetails.draw(in: receiptRect)
                yOffset += 80 + paragraphSpacing
                
                // 🔹 Thank You Section
                let thankYouText = NSMutableAttributedString(string: "Thank You!\n", attributes: [
                    .font: UIFont.boldSystemFont(ofSize: fontSize),
                    .paragraphStyle: leftAlignedParagraphStyle()
                ])
                
                let message = """
            Your generous donation helps us to continue our mission.
            
            If you have any questions regarding this receipt, please contact us:
            Email: \(String(describing: organizationProvider.organizationInfo.email))
            Phone: \(String(describing: organizationProvider.organizationInfo.phone))
            """
                let messageAttributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .paragraphStyle: justifiedParagraphStyle()
                ]
                thankYouText.append(NSAttributedString(string: message, attributes: messageAttributes))
                
                let thankYouRect = CGRect(x: margin, y: yOffset, width: pageSize.width - 2 * margin, height: 120)
                thankYouText.draw(in: thankYouRect)
                yOffset += 120 + paragraphSpacing
                
                // 🔹 Footer
                let footerText = """
            \(organizationProvider.organizationInfo.name)
            This receipt is valid for tax purposes.
            """
                let footerAttributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .paragraphStyle: centeredParagraphStyle()
                ]
                let footerRect = CGRect(x: margin, y: yOffset, width: pageSize.width - 2 * margin, height: 40)
                footerText.draw(in: footerRect, withAttributes: footerAttributes)
                
            })
            return pdfFilePath
        } catch {
            print("Failed to create PDF: \(error)")
            return nil
        }
    }
}
