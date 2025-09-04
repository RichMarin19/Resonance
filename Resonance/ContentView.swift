//
//  ContentView.swift
//  Resonance
//
//  Created by Claude on 9/3/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            if appState.isShowingSplash {
                SplashView()
                    .transition(.opacity)
            } else if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.slide)
            } else {
                DashboardView()
                    .transition(.slide)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appState.isShowingSplash)
        .animation(.easeInOut(duration: 0.5), value: appState.hasCompletedOnboarding)
    }
}

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var visualScore = 0
    @State private var auditoryScore = 0
    @State private var kinestheticScore = 0
    
    let vakQuestions = [
        VAKQuestion(question: "When learning something new, I prefer to:", 
                   visual: "See diagrams and visual examples",
                   auditory: "Listen to explanations",
                   kinesthetic: "Practice hands-on"),
        VAKQuestion(question: "When stressed, I find relief by:",
                   visual: "Looking at calming images or organizing my space",
                   auditory: "Listening to music or talking to someone",
                   kinesthetic: "Going for a walk or doing physical exercise"),
        VAKQuestion(question: "I remember information best when:",
                   visual: "I can see it written down or in charts",
                   auditory: "I hear it explained or discuss it",
                   kinesthetic: "I can practice or experience it")
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            if currentStep < vakQuestions.count {
                Text("Learning Style Assessment")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primaryBlue)
                
                Text("Question \(currentStep + 1) of \(vakQuestions.count)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(vakQuestions[currentStep].question)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    
                    Button(vakQuestions[currentStep].visual) {
                        visualScore += 1
                        nextQuestion()
                    }
                    .buttonStyle(VAKButtonStyle(color: .visualPurple))
                    
                    Button(vakQuestions[currentStep].auditory) {
                        auditoryScore += 1
                        nextQuestion()
                    }
                    .buttonStyle(VAKButtonStyle(color: .auditoryTeal))
                    
                    Button(vakQuestions[currentStep].kinesthetic) {
                        kinestheticScore += 1
                        nextQuestion()
                    }
                    .buttonStyle(VAKButtonStyle(color: .kinestheticOrange))
                }
                .padding()
            } else {
                // Results
                Text("Your Learning Style")
                    .font(.title)
                    .fontWeight(.bold)
                
                let dominantStyle = determineLearningStyle()
                Text(dominantStyle.rawValue)
                    .font(.title2)
                    .foregroundColor(dominantStyle.color)
                
                Text(dominantStyle.description)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Start Using Resonance") {
                    appState.userLearningStyle = dominantStyle
                    appState.hasCompletedOnboarding = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
    }
    
    private func nextQuestion() {
        currentStep += 1
    }
    
    private func determineLearningStyle() -> LearningStyle {
        let scores = [
            (LearningStyle.visual, visualScore),
            (LearningStyle.auditory, auditoryScore),
            (LearningStyle.kinesthetic, kinestheticScore)
        ]
        
        return scores.max(by: { $0.1 < $1.1 })?.0 ?? .visual
    }
}

struct VAKQuestion {
    let question: String
    let visual: String
    let auditory: String
    let kinesthetic: String
}

struct VAKButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.primaryBlue.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}