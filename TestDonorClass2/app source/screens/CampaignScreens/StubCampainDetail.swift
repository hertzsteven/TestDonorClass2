import SwiftUI
struct StubCampainDetail: View {
    let campaign: Campaign
    
    var body: some View {
        VStack {
            Text("Hello, World!")
            Text(campaign.name)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("Campaign Detail View Appeared - Current")
        }
        .onDisappear {
            print("Campaign Detail View Disappeared - Current")
        }
    }
}
