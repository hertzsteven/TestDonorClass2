import SwiftUI

struct HelpCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedSection: HelpSection?
    
    private var sections = HelpSection.mockSections
    
    var filteredSections: [HelpSection] {
        if searchText.isEmpty {
            return sections
        }
        return sections.filter { section in
            section.title.localizedCaseInsensitiveContains(searchText) ||
            section.content.contains { content in
                content.title.localizedCaseInsensitiveContains(searchText) ||
                content.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(filteredSections, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    Label {
                        Text(section.title)
                    } icon: {
                        Image(systemName: section.icon)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .navigationTitle("Help Center")
            .searchable(text: $searchText, prompt: "Search help topics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        } detail: {
            if let section = selectedSection {
                HelpDetailView(section: section)
            } else {
                ContentUnavailableView(
                    "Select a Help Topic",
                    systemImage: "book.circle",
                    description: Text("Choose a topic from the sidebar to view help content")
                )
            }
        }
    }
}

#Preview {
    HelpCenterView()
}