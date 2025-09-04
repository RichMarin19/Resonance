import SwiftUI

struct BetaWelcomeView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
            .padding()
            
            TabView(selection: $currentPage) {
                // Welcome Page
                VStack(spacing: 20) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.purple.opacity(0.3), .blue.opacity(0.3)], 
                                             startPoint: .topLeading, 
                                             endPoint: .bottomTrailing)
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(colors: [.purple, .blue], 
                                             startPoint: .topLeading, 
                                             endPoint: .bottomTrailing)
                            )
                    }
                    
                    VStack(spacing: 12) {
                        Text("Welcome to")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Resonance")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("BETA")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    LinearGradient(colors: [.purple, .blue], 
                                                 startPoint: .leading, 
                                                 endPoint: .trailing)
                                )
                                .cornerRadius(8)
                                .offset(y: -8)
                        }
                    }
                    
                    Text("You're among the first to experience our wellness tracking revolution")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    Spacer()
                }
                .tag(0)
                
                // What's New Page
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text("What's New")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(
                            icon: "brain.head.profile",
                            title: "Stress & Energy Tracking",
                            description: "Advanced algorithms analyze your health data to calculate daily stress and energy levels"
                        )
                        
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "11 Health Metrics",
                            description: "Track mood, sleep, heart rate, HRV, steps, and more in one beautiful dashboard"
                        )
                        
                        FeatureRow(
                            icon: "figure.run",
                            title: "Activity Tracking",
                            description: "Monitor your wellness activities with real-time heart rate and mood correlation"
                        )
                        
                        FeatureRow(
                            icon: "heart.text.square",
                            title: "Personalized Insights",
                            description: "Get AI-powered recommendations based on your unique patterns"
                        )
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .tag(1)
                
                // Beta Info Page
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "testtube.2")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(colors: [.purple, .blue], 
                                         startPoint: .topLeading, 
                                         endPoint: .bottomTrailing)
                        )
                    
                    Text("You're a Beta Tester!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 16) {
                        Text("As a beta tester, you're helping shape the future of Resonance")
                            .font(.body)
                            .multilineTextAlignment(.center)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Early access to new features")
                                    .font(.subheadline)
                            }
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Direct impact on app development")
                                    .font(.subheadline)
                            }
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Priority support from our team")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    Text("Please share your feedback using the 💬 button")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Text("Start Tracking")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.blue, .purple], 
                                             startPoint: .leading, 
                                             endPoint: .trailing)
                            )
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .blue], 
                                 startPoint: .topLeading, 
                                 endPoint: .bottomTrailing)
                )
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    BetaWelcomeView(isPresented: .constant(true))
}