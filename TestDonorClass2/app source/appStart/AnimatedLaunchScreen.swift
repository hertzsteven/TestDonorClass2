import SwiftUI

struct AnimatedLaunchScreen: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var rotation: Double = -10
    @State private var isLogoAnimationComplete = false
    
    @Binding var showLaunchScreen: Bool
    
    fileprivate func doAnimation01() {
        // Animate the logo appearance
        withAnimation(.easeOut(duration: 0.8)) {
            scale = 1.0
            opacity = 1.0
            rotation = 0
        }
        
        // After logo animation completes, show the text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                isLogoAnimationComplete = true
            }
        }
        
        // After all animations complete, set isFinished to true to move to main app
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                // Optional fade out before transitioning
                opacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                // IMPORTANT: This is where we signal to transition to the main app
                showLaunchScreen = false
            }
        }
    }
    fileprivate func doAnimation02() {
        // Logo animation
        withAnimation(Animation.easeOut(duration: 0.8)) {
            scale = 1.0
            opacity = 1.0
            rotation = 0
        }
        
        // Text animation with delay
        withAnimation(Animation.easeIn(duration: 0.5).delay(1.0)) {
            isLogoAnimationComplete = true
        }
        
        // Fade-out animation with delay
        withAnimation(Animation.easeOut(duration: 0.5).delay(2.5)) {
            opacity = 0
        }

        // Transition after all animations complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
            showLaunchScreen = false // Adjust as needed for your logic
        }
    }
    
    var body: some View {
        ZStack {
            // Background color
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Logo animation
            VStack {
                ApplicationData.shared.getOrgLogoImage()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isLogoAnimationComplete ? 200 : 180)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .rotationEffect(.degrees(rotation))
                
                if isLogoAnimationComplete {
                    Text("\(ApplicationData.shared.getOrgTitle())")
                        .font(.title)
                        .fontWeight(.bold)
                        .opacity(opacity)
                        .padding(.top, 20)
                    
                    Text("Donation Management")
                        .font(.subheadline)
                        .opacity(opacity)
                        .padding(.top, 4)
                }
            }
        }
        .onAppear {
            doAnimation02()
        }
    }
}

// Coordinator view to handle launch screen state
struct LaunchScreenManager: View {
    // Changed to @State to ensure view updates when it changes
    @State private var showLaunchScreen: Bool = true
    
    var body: some View {
        ZStack {
            // Your main app content
            if !showLaunchScreen {
                // Replace this with your app's main entry point view
                MainAppView()
            }
            
            // Launch screen overlay if still showing
            if showLaunchScreen {
                AnimatedLaunchScreen(showLaunchScreen: $showLaunchScreen)
                    .transition(.opacity) // Added transition effect
            }
        }
        .animation(.default, value: showLaunchScreen) // Animate the change in showLaunchScreen
    }
}

// Example main app view - replace with your actual main view
struct MainAppView: View {
    var body: some View {
        // Your main app content would go here
        // This is just a placeholder
        DashboardView()
            .transition(.opacity) // Optional: add transition for the main view
//            .environmentObject(donorObject)
//            .environmentObject(donationObject)
//            .environmentObject(campaignObject)
//            .environmentObject(incentiveObject)
//            .environmentObject(defaultDonationSettingsViewModel)
    }
}

// Preview for development
struct AnimatedLaunchScreen_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenManager()
    }
}

/*
// Placeholder for your dashboard view
struct DashboardView2: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to the Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Donation Management System")
                    .font(.title2)
                
                // Your dashboard content here
            }
            .navigationTitle("Dashboard")
        }
    }
}
*/
