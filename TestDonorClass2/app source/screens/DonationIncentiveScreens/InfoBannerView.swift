    private struct InfoBannerView: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Managing Donation Incentives")
                    .font(.headline)
                
                Text("• Tap + to add a new incentive")
                Text("• Tap any incentive to view or edit details")
                Text("• Swipe left on an incentive to delete")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }