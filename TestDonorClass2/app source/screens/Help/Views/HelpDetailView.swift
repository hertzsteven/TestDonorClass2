import SwiftUI

struct HelpDetailView: View {
    let section: HelpSection
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(section.content) { content in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(content.title)
                            .font(.title3)
                            .bold()
                        
                        Text(content.description)
                            .foregroundStyle(.secondary)
                        
                        if !content.steps.isEmpty {
                            Text("Steps:")
                                .font(.headline)
                                .padding(.top, 4)
                            
                            ForEach(content.steps.indices, id: \.self) { index in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(index + 1).")
                                        .foregroundStyle(.secondary)
                                    Text(content.steps[index])
                                }
                                .padding(.leading, 4)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 5)
                    )
                }
            }
            .padding()
        }
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HelpDetailView(section: HelpSection.mockSections[0])
    }
}