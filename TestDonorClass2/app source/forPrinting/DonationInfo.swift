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
    let donorAddress: String?
    let donorCity: String?
    let donorState: String?
    let donorZip: String?
    
    // Computed property for formatted address
    var formattedAddress: String {
        var addressLines: [String] = []
        
        if let address = donorAddress, !address.isEmpty {
            addressLines.append(address)
        }
        
        var cityStateZip: [String] = []
        if let city = donorCity, !city.isEmpty {
            cityStateZip.append(city)
        }
        if let state = donorState, !state.isEmpty {
            cityStateZip.append(state)
        }
        if let zip = donorZip, !zip.isEmpty {
            cityStateZip.append(zip)
        }
        
        if !cityStateZip.isEmpty {
            addressLines.append(cityStateZip.joined(separator: ", "))
        }
        
        return addressLines.joined(separator: "\n")
    }
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
    private func createReceiptPDFOld(for donation: DonationInfo) -> URL? {
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
                
                // 📧 ENVELOPE WINDOW POSITIONING
                // Convert inches to points (1 inch = 72 points)
                
                // 📧 Address Information (using let declarations)
                let organizationName = "Your Organization Name"
                let organizationAddress = "123 Main Street"
                let organizationCity = "Your City"
                let organizationState = "ST"
                let organizationZipCode = "12345"
                
                let donorName = donation.donorName
                let donorAddress = donation.donorAddress ?? "No address provided"
                let donorCity = donation.donorCity ?? ""
                let donorState = donation.donorState ?? ""
                let donorZip = donation.donorZip ?? ""
                
                // Return Address Window (Upper Left) - Organization Address
                let returnAddressX: CGFloat = 36 // ~0.5" from left
                let returnAddressY: CGFloat = 36 // ~0.5" from top
                let returnAddressWidth: CGFloat = 252 // ~3.5"
                let returnAddressHeight: CGFloat = 63 // ~0.875"
                
                let returnAddressRect = CGRect(
                    x: returnAddressX,
                    y: returnAddressY,
                    width: returnAddressWidth,
                    height: returnAddressHeight
                )
                
                let organizationAddressText = """
                \(organizationName)
                \(organizationAddress)
                \(organizationCity), \(organizationState) \(organizationZipCode)
                """
                
                let returnAddressAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .paragraphStyle: leftAlignedParagraphStyle()
                ]
                
                organizationAddressText.draw(in: returnAddressRect, withAttributes: returnAddressAttributes)
                
                // Recipient Address Window (Center) - Donor Address
                let recipientAddressX: CGFloat = 36 // ~4" from left
                let recipientAddressY: CGFloat = 198 // ~2.75" from top
                let recipientAddressWidth: CGFloat = 297 // ~4.125"
                let recipientAddressHeight: CGFloat = 81 // ~1.125"
                
                let recipientAddressRect = CGRect(
                    x: recipientAddressX,
                    y: recipientAddressY,
                    width: recipientAddressWidth,
                    height: recipientAddressHeight
                )
                
                var donorAddressLines: [String] = [donorName]
                if !donorAddress.isEmpty {
                    donorAddressLines.append(donorAddress)
                }
                
                var cityStateZip: [String] = []
                if !donorCity.isEmpty { cityStateZip.append(donorCity) }
                if !donorState.isEmpty { cityStateZip.append(donorState) }
                if !donorZip.isEmpty { cityStateZip.append(donorZip) }
                
                if !cityStateZip.isEmpty {
                    donorAddressLines.append(cityStateZip.joined(separator: ", "))
                }
                
                let donorAddressText = donorAddressLines.joined(separator: "\n")
                
                let recipientAddressAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11),
                    .paragraphStyle: leftAlignedParagraphStyle()
                ]
                
                donorAddressText.draw(in: recipientAddressRect, withAttributes: recipientAddressAttributes)
                
                // Move yOffset down past the address windows
                yOffset = max(returnAddressY + returnAddressHeight, recipientAddressY + recipientAddressHeight) + paragraphSpacing
                
                // 🖼 Draw the header image (if available) - positioned below address windows
                if let headerImage = UIImage(named: "header") {
                    let imageWidth: CGFloat = 75
                    let imageHeight: CGFloat = 75
                    let imageX = pageSize.width - margin - imageWidth // Position image on the right
                    let textStartX = margin // Keep text on the left
                    
                    // Position image on the right
                    let imageRect = CGRect(x: imageX, y: yOffset, width: imageWidth, height: imageHeight)
                    headerImage.draw(in: imageRect)
                    
                    // Get the organization information from the let declarations above
                    // 🏷 Organization Header (placed to the left of the image)
                    let organizationText = "\(organizationName)\n\(organizationAddress)\n\(organizationCity), \(organizationState) \(organizationZipCode)"

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
            Email: contact@yourorganization.org
            Phone: (555) 123-4567
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
            \(organizationName)
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