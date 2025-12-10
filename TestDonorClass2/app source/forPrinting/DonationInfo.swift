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
    let donorTitle: String?
    let donationAmount: Double
    let date: String
    let donorAddress: String?
    let donorCity: String?
    let donorState: String?
    let donorZip: String?
    let receiptNumber: String? 
    
    // Computed property for formatted donor name with title
    var formattedDonorName: String {
        if let title = donorTitle, !title.isEmpty {
            // Add period if title doesn't already have one
            let formattedTitle = title.hasSuffix(".") ? title : "\(title)."
            return "\(formattedTitle) \(donorName)"
        }
        return donorName
    }
    
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

    /// Layout constants for receipt PDF.
    private struct Layout {
        static let pageMargin: CGFloat = 50
        static let paragraphSpacing: CGFloat = 20
        
        // Return address (envelope format)
        static let envelopeMarginX: CGFloat = 36      // 0.5" from left
        static let envelopeMarginY: CGFloat = 28      // 0.5" from top
//        static let envelopeMarginY: CGFloat = 36      // 0.5" from top
        static let envelopeWidth: CGFloat = 252       // 3.5" wide
        static let envelopeHeight: CGFloat = 63       // 0.875" high
        
        // Updated recipient positioning for standard window envelope compatibility
        static let recipientWidth: CGFloat = 252      // 3.5" wide
        static let recipientHeight: CGFloat = 81      // 1.125" high
        static let recipientMarginX: CGFloat = 60    // 2" from left edge
//        static let recipientMarginX: CGFloat = 144    // 2" from left edge
        static let recipientMarginY: CGFloat = 425    // 2" from top edge
//        static let recipientMarginY: CGFloat = 144    // 2" from top edge

        // Header section with organization info
        static let headerMarginX: CGFloat = 50        // 0.69" from left (50/72)
        static let headerMarginY: CGFloat = 0         // 0" from top
        static let headerWidth: CGFloat = 512         // 7.11" wide (512/72)
        static let headerHeight: CGFloat = 60         // 0.83" high (60/72)
        
        // Title section  
        static let titleMarginX: CGFloat = 50         // 0.69" from left (50/72)
        static let titleMarginY: CGFloat = 80         // 1.11" from top (80/72)
        static let titleWidth: CGFloat = 512          // 7.11" wide (512/72)
        static let titleHeight: CGFloat = 30          // 0.42" high (30/72)
        
        // Receipt details section
        static let receiptDetailsMarginX: CGFloat = 50    // 0.69" from left (50/72)
        static let receiptDetailsMarginY: CGFloat = 302   // 3.40" from top (245/72)
        static let receiptDetailsWidth: CGFloat = 512     // 7.11" wide (512/72)
        static let receiptDetailsHeight: CGFloat = 120     // 1.11" high (80/72)
        
        // Thank you section
        static let thankYouMarginX: CGFloat = 50      // 0.69" from left (50/72)
        static let thankYouMarginY: CGFloat = 362     // 4.79" from top (345/72)
        static let thankYouWidth: CGFloat = 512       // 7.11" wide (512/72)
        static let thankYouHeight: CGFloat = 120      // 1.67" high (120/72)
        
        // Footer section
        static let footerMarginX: CGFloat = 50        // 0.69" from left (50/72)
        static let footerMarginY: CGFloat = 485       // 6.74" from top (485/72)
        static let footerWidth: CGFloat = 512         // 7.11" wide (512/72)
        static let footerHeight: CGFloat = 40         // 0.56" high (40/72)
    }
    
    /// A nested struct to hold all the formatting constants for the PDF receipt.
    private struct PDFFormatting {
        // MARK: - Fonts
        static let titleFont = UIFont.boldSystemFont(ofSize: 18)
        static let headerFont = UIFont.boldSystemFont(ofSize: 12)
        static let bodyFont = UIFont.systemFont(ofSize: 12)
        static let recipientFont = UIFont.systemFont(ofSize: 11)
        static let returnAddressFont = UIFont.systemFont(ofSize: 10)

        // MARK: - Paragraph Styles
        static let leftAlign = leftAlignedParagraphStyle()
        static let centerAlign = centeredParagraphStyle()
        static let justifiedAlign = justifiedParagraphStyle()
        
        // MARK: - Attribute Dictionaries
        static let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .paragraphStyle: centerAlign
        ]
        
        static let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .paragraphStyle: leftAlign
        ]

        static let bodyLeftAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .paragraphStyle: leftAlign
        ]
        
        static let bodyJustifiedAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .paragraphStyle: justifiedAlign
        ]

        static let bodyCenteredAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .paragraphStyle: centerAlign
        ]

        static let recipientAddressAttributes: [NSAttributedString.Key: Any] = [
            .font: recipientFont,
            .paragraphStyle: leftAlign
        ]

        static let returnAddressAttributes: [NSAttributedString.Key: Any] = [
            .font: returnAddressFont,
            .paragraphStyle: leftAlign
        ]
    }
    
    private let organizationProvider: OrganizationProvider
    // Add static reference to maintain print controller across instances
    private static var activePrintController: UIPrintInteractionController?

    /// Dependency injection of the organization provider.
    init(organizationProvider: OrganizationProvider = DefaultOrganizationProvider()) {
        self.organizationProvider = organizationProvider
    }

    /// Public method to print a receipt based on the donation information.
    func printReceipt(for donation: DonationInfo, completion: @escaping (Bool) -> Void) {
        print("Starting to print receipt in ReceiptPrintingService for \(donation.donorName)")
        guard let pdfURL = createReceiptPDF(for: donation) else {
            print("Error: Failed to generate receipt PDF.")
            completion(false)
            return
        }
        
        DispatchQueue.main.async {
            // Store in static property to ensure it stays alive across the app
            ReceiptPrintingService.activePrintController = UIPrintInteractionController.shared
            ReceiptPrintingService.activePrintController?.printingItem = pdfURL
            
            // Configure print job settings
            let printInfo = UIPrintInfo.printInfo()
            printInfo.outputType = .general  // Good for documents with text
            printInfo.jobName = "Donation Receipt - \(donation.formattedDonorName)"
            printInfo.orientation = .portrait
            ReceiptPrintingService.activePrintController?.printInfo = printInfo
            
            print("About to present print controller")
            ReceiptPrintingService.activePrintController?.present(animated: true) { (controller, completed, error) in
                print("Print controller dismissed, completed: \(completed), error: \(String(describing: error))")
                // Pass the actual completion status to the caller
                completion(completed)
                // Clear the static reference after completion
                DispatchQueue.main.async {
                    ReceiptPrintingService.activePrintController = nil
                }
            }
        }
    }
    
    /// Public method to print multiple receipts as a single multi-page PDF.
    /// Each receipt will be on its own page.
    func printReceipts(for donations: [DonationInfo], completion: @escaping (Bool) -> Void) {
        print("Starting to print \(donations.count) receipts in ReceiptPrintingService")
        
        guard !donations.isEmpty else {
            print("Error: No donations to print.")
            completion(false)
            return
        }
        
        guard let pdfURL = createMultiReceiptPDF(for: donations) else {
            print("Error: Failed to generate multi-receipt PDF.")
            completion(false)
            return
        }
        
        DispatchQueue.main.async {
            // Store in static property to ensure it stays alive across the app
            ReceiptPrintingService.activePrintController = UIPrintInteractionController.shared
            ReceiptPrintingService.activePrintController?.printingItem = pdfURL
            
            // Configure print job settings
            let printInfo = UIPrintInfo.printInfo()
            printInfo.outputType = .general  // Good for documents with text
            printInfo.jobName = "Donation Receipts (\(donations.count) receipts)"
            printInfo.orientation = .portrait
            ReceiptPrintingService.activePrintController?.printInfo = printInfo
            
            print("About to present print controller for \(donations.count) receipts")
            ReceiptPrintingService.activePrintController?.present(animated: true) { (controller, completed, error) in
                print("Print controller dismissed, completed: \(completed), error: \(String(describing: error))")
                // Pass the actual completion status to the caller
                completion(completed)
                // Clear the static reference after completion
                DispatchQueue.main.async {
                    ReceiptPrintingService.activePrintController = nil
                }
            }
        }
    }
    
    /// Creates a single PDF with multiple pages, one for each donation.
    private func createMultiReceiptPDF(for donations: [DonationInfo]) -> URL? {
        let pageSize = CGSize(width: 612, height: 792) // 8.5" x 11"
        let pdfFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("receipts_batch.pdf")
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        do {
            try renderer.writePDF(to: pdfFilePath, withActions: { context in
                let orgInfo = self.organizationProvider.organizationInfo
                
                for donation in donations {
                    // Start a new page for each receipt
                    context.beginPage()
                    
                    var yOffset: CGFloat = 0
                    
                    // Draw the receipt content (same as single receipt)
                    yOffset = drawReturnAddress(in: context, orgInfo: orgInfo)
                    yOffset = drawReceiptDetails(in: context, donation: donation, yOffset: yOffset)
                    yOffset = drawThankYouSection(in: context, orgInfo: orgInfo, yOffset: yOffset)
                    _ = drawRecipientAddress(in: context, donation: donation)
                }
            })
            return pdfFilePath
        } catch {
            print("Failed to create multi-receipt PDF: \(error)")
            return nil
        }
    }

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
                
                // Draw the header image (if available)
                if let headerImage = UIImage(named: "header") {
                    let imageWidth: CGFloat = 75
                    let imageHeight: CGFloat = 75
                    let imageX = pageSize.width - margin - imageWidth // Position image on the right
                    let textStartX = margin // Keep text on the left
                    
                    // Position image on the right
                    let imageRect = CGRect(x: imageX, y: yOffset, width: imageWidth, height: imageHeight)
                    headerImage.draw(in: imageRect)
                    
                    // Get the organization information from the injected provider.
                    // Organization Header (placed to the left of the image)
                    let organizationText = organizationProvider.organizationInfo.formattedInfo

                    let orgAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: fontSize),
                        .paragraphStyle: leftAlignedParagraphStyle()
                    ]
                    let orgRect = CGRect(x: textStartX, y: yOffset, width: imageX - textStartX - 10, height: 60)
                    organizationText.draw(in: orgRect, withAttributes: orgAttributes)
                    
                    yOffset += max(imageHeight, 60) + paragraphSpacing // Move down based on tallest element
                }
                
                // Receipt Title
                let title = "Donation Receipt"
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .paragraphStyle: centeredParagraphStyle()
                ]
                let titleRect = CGRect(x: margin, y: yOffset, width: pageSize.width - 2 * margin, height: 30)
                title.draw(in: titleRect, withAttributes: titleAttributes)
                yOffset += 40 + paragraphSpacing
                
                // Receipt Information
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
                
                // Thank You Section
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
                
                // Footer
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

                let orgInfo = self.organizationProvider.organizationInfo
                var yOffset: CGFloat = 0

               // yOffset = drawHeaderSection(in: context, orgInfo: orgInfo, yOffset: yOffset)
//                yOffset = drawTitle(in: context, yOffset: yOffset)
                
//                yOffset = drawHeaderSection(in: context, orgInfo: orgInfo, yOffset: yOffset)
                yOffset = drawReturnAddress(in: context, orgInfo: orgInfo)
                
                               yOffset = drawReceiptDetails(in: context, donation: donation, yOffset: yOffset)
                               yOffset = drawThankYouSection(in: context, orgInfo: orgInfo, yOffset: yOffset)
                yOffset = drawRecipientAddress(in: context, donation: donation)
                // …then title, details, etc.
                
                
//                yOffset = drawReturnAddress(in: context, orgInfo: orgInfo)
//                yOffset = drawRecipientAddress(in: context, donation: donation, yOffset: yOffset)
// 
//                yOffset = drawReceiptDetails(in: context, donation: donation, yOffset: yOffset)
//                yOffset = drawThankYouSection(in: context, orgInfo: orgInfo, yOffset: yOffset)
//                _ = drawFooter(in: context, orgInfo: orgInfo, yOffset: yOffset)
            })
            return pdfFilePath
        } catch {
            print("Failed to create PDF: \(error)")
            return nil
        }
    }

    // MARK: - Drawing helper methods
    private func drawReturnAddress(in context: UIGraphicsPDFRendererContext, orgInfo: OrganizationInfo) -> CGFloat {
        let rect = CGRect(
            x: Layout.envelopeMarginX,
            y: Layout.envelopeMarginY,
            width: Layout.envelopeWidth,
            height: Layout.envelopeHeight
        )
        let text = ""
/*

        let text = """
\(orgInfo.name)
\(orgInfo.addressLine1)
\(orgInfo.city), \(orgInfo.state) \(orgInfo.zip)
"""
 */
        text.draw(in: rect, withAttributes: PDFFormatting.returnAddressAttributes)
        return rect.maxY + Layout.paragraphSpacing
    }

    private func drawRecipientAddress(in context: UIGraphicsPDFRendererContext,
                                      donation: DonationInfo) -> CGFloat {
        let rect = CGRect(x: Layout.recipientMarginX,
                          y: Layout.recipientMarginY,
                          width: Layout.recipientWidth,
                          height: Layout.recipientHeight)

        var donorLines: [String] = [donation.formattedDonorName]
        if let addr = donation.donorAddress, !addr.isEmpty {
            donorLines.append(addr)
        }
        var cityStateZip: [String] = []
        if let c = donation.donorCity, !c.isEmpty { cityStateZip.append(c) }
        if let s = donation.donorState, !s.isEmpty { cityStateZip.append(s) }
        if let z = donation.donorZip, !z.isEmpty { cityStateZip.append(z) }
        if !cityStateZip.isEmpty {
            donorLines.append(cityStateZip.joined(separator: ", "))
        }
        let text = donorLines.joined(separator: "\n")
        text.draw(in: rect, withAttributes: PDFFormatting.recipientAddressAttributes)
        return rect.maxY + Layout.paragraphSpacing
    }

    private func drawHeaderSection(in context: UIGraphicsPDFRendererContext, orgInfo: OrganizationInfo, yOffset: CGFloat) -> CGFloat {
        let pageSize = context.pdfContextBounds.size
        let margin = Layout.pageMargin
        var y = yOffset
        // Just draw the organization text—no logo.
        let organizationText = """
        \(orgInfo.name)
        \(orgInfo.addressLine1)
        \(orgInfo.city), \(orgInfo.state) \(orgInfo.zip)
        """
        // Full page width minus margins
        let textRect = CGRect(
            x: margin,
            y: y,
            width: pageSize.width - 2 * margin,
            height: 60
        )
        organizationText.draw(in: textRect, withAttributes: PDFFormatting.headerAttributes)

        // Advance past the text block
        y += 60 + Layout.paragraphSpacing
        return y
    }

    private func drawTitle(in context: UIGraphicsPDFRendererContext, yOffset: CGFloat) -> CGFloat {
        let pageSize = context.pdfContextBounds.size
        let margin = Layout.pageMargin
        let title = "Donation Receipt"
        let titleRect = CGRect(x: margin, y: yOffset, width: pageSize.width - 2 * margin, height: 30)
        title.draw(in: titleRect, withAttributes: PDFFormatting.titleAttributes)
        return yOffset + 40 + Layout.paragraphSpacing
    }

    private func drawReceiptDetails(in context: UIGraphicsPDFRendererContext, donation: DonationInfo, yOffset: CGFloat) -> CGFloat {
        let pageSize = context.pdfContextBounds.size
        let margin = Layout.pageMargin
        let receiptDetails = NSMutableAttributedString(string: "\n", attributes: PDFFormatting.headerAttributes)

        // Include receipt number if available
        let receiptNumberText = donation.receiptNumber ?? "N/A"

        let details = """
Receipt Number: \(receiptNumberText)
Date: \(donation.date)
Donation Amount: $\(String(format: "%.2f", donation.donationAmount))
"""
//        let details = """
//Receipt Number: \(receiptNumberText)
//Date: \(donation.date)
//
//Donor Name: \(donation.formattedDonorName)
//Donation Amount: $\(String(format: "%.2f", donation.donationAmount))
//"""
        receiptDetails.append(NSAttributedString(string: details, attributes: PDFFormatting.bodyLeftAttributes))
        
        let receiptRect = CGRect(x: margin, y: yOffset, width: pageSize.width - 2 * margin, height: 80)
        
        let receiptRectFixed = CGRect(x: Layout.receiptDetailsMarginX,
                                 y: Layout.receiptDetailsMarginY,
                                 width: Layout.receiptDetailsWidth,
                                 height: Layout.receiptDetailsHeight)
        
        receiptDetails.draw(in: receiptRectFixed)
        return yOffset + 80 + Layout.paragraphSpacing
    }

    private func drawThankYouSection(in context: UIGraphicsPDFRendererContext, orgInfo: OrganizationInfo, yOffset: CGFloat) -> CGFloat {
        let pageSize = context.pdfContextBounds.size
        let margin = Layout.pageMargin
        let thankYouText = NSMutableAttributedString(string: "Thank You!", attributes: PDFFormatting.headerAttributes)
        thankYouText.append(NSAttributedString(string: "    No goods or services were received in exchange for this donation.\n", attributes: PDFFormatting.bodyLeftAttributes))
        let message = """
Your generous donation helps us to continue our mission.

"""
//        let message = """
//Your generous donation helps us to continue our mission.
//
//If you have any questions regarding this receipt, please contact us:
//Email: \(orgInfo.email ?? "contact@organization.org")
//Phone: \(orgInfo.phone ?? "Phone not available")
//Website: \(orgInfo.website ?? "")
//"""
        thankYouText.append(NSAttributedString(string: message, attributes: PDFFormatting.bodyJustifiedAttributes))
        
        let thankYouRect = CGRect(x: margin, y: yOffset, width: pageSize.width - 2 * margin, height: 120)
        
        let thankYouRectFixed = CGRect(x: Layout.thankYouMarginX,
                                  y: Layout.thankYouMarginY,
                                  width: Layout.thankYouWidth,
                                  height: Layout.thankYouHeight)
        
        thankYouText.draw(in: thankYouRectFixed)
        
        return yOffset + 120 + Layout.paragraphSpacing
    }

    private func drawFooter(in context: UIGraphicsPDFRendererContext, orgInfo: OrganizationInfo, yOffset: CGFloat) -> CGFloat {
        let pageSize = context.pdfContextBounds.size
        let margin = Layout.pageMargin
        let footerText = """
\(orgInfo.name)
EIN: \(orgInfo.ein)
This receipt is valid for tax purposes.
"""
        let footerRect = CGRect(x: margin, y: yOffset, width: pageSize.width - 2 * margin, height: 40)
        let footerRectFixed = CGRect(x: Layout.footerMarginX,
                                y: Layout.footerMarginY,
                                width: Layout.footerWidth,
                                height: Layout.footerHeight)

        footerText.draw(in: footerRectFixed, withAttributes: PDFFormatting.bodyCenteredAttributes)
        
        return yOffset + 40
    }
}
