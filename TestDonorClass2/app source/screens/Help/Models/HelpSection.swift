import Foundation

struct HelpSection: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
    let content: [HelpContent]
    
    static func == (lhs: HelpSection, rhs: HelpSection) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct HelpContent: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let steps: [String]
    
    static func == (lhs: HelpContent, rhs: HelpContent) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Mock Data
extension HelpSection {
    static let mockSections = [
        HelpSection(
            title: "Getting Started",
            icon: "star",
            content: [
                HelpContent(
                    title: "Dashboard Overview",
                    description: "Learn how to navigate the main dashboard and access key features.",
                    steps: [
                        "The dashboard is organized into three main sections",
                        "Donor Donation Management for handling donations",
                        "Campaign & Incentives for managing fundraising",
                        "Reports & Analytics for tracking progress"
                    ]
                ),
                HelpContent(
                    title: "First Time Setup",
                    description: "Configure your organization's essential information.",
                    steps: [
                        "Click the Settings gear icon",
                        "Enter your organization details",
                        "Set up your first campaign",
                        "Add donor information"
                    ]
                )
            ]
        ),
        HelpSection(
            title: "Donor Management",
            icon: "person.2",
            content: [
                HelpContent(
                    title: "Adding New Donors",
                    description: "Learn how to add and manage donor information.",
                    steps: [
                        "Navigate to Donor Hub",
                        "Click the + button",
                        "Fill in donor details",
                        "Save the new donor record"
                    ]
                ),
                HelpContent(
                    title: "Recording Donations",
                    description: "Process and record new donations.",
                    steps: [
                        "Select a donor",
                        "Click 'New Donation'",
                        "Enter donation details",
                        "Choose payment method",
                        "Complete the transaction"
                    ]
                )
            ]
        ),
        HelpSection(
            title: "Campaigns",
            icon: "megaphone",
            content: [
                HelpContent(
                    title: "Creating Campaigns",
                    description: "Set up and manage fundraising campaigns.",
                    steps: [
                        "Go to Campaigns section",
                        "Click 'New Campaign'",
                        "Set campaign goals",
                        "Define donation levels",
                        "Launch the campaign"
                    ]
                )
            ]
        ),
        HelpSection(
            title: "Reports",
            icon: "chart.bar",
            content: [
                HelpContent(
                    title: "Generating Reports",
                    description: "Create and export donation reports.",
                    steps: [
                        "Navigate to Reports section",
                        "Select report type",
                        "Choose date range",
                        "Filter by campaign or donor",
                        "Export or print report"
                    ]
                )
            ]
        )
    ]
}