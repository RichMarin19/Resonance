//
//  SplashView.swift
//  Resonance
//
//  Created by Claude on 9/3/25.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appState: AppState
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Blue gradient background
            LinearGradient(
                colors: [
                    Color.primaryBlue.opacity(0.8),
                    Color.primaryBlue,
                    Color.primaryBlue.darker()
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo/App Icon Area
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    // Simple wave icon representing "Resonance"
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                VStack(spacing: 10) {
                    Text("Resonance")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(logoOpacity)
                    
                    Text("Health tracking for stressed professionals")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(logoOpacity)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // Auto-dismiss splash screen after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    appState.isShowingSplash = false
                }
            }
        }
    }
}

extension Color {
    func darker(by amount: CGFloat = 0.2) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: max(0, brightness - amount), alpha: alpha))
    }
}

#Preview {
    SplashView()
        .environmentObject(AppState())
}