//
//  ResonanceApp.swift
//  Resonance
//
//  Created by Claude on 9/3/25.
//

import SwiftUI

@main
struct ResonanceApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

class AppState: ObservableObject {
    @Published var isShowingSplash = true
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    @Published var userLearningStyle: LearningStyle {
        didSet {
            UserDefaults.standard.set(userLearningStyle.rawValue, forKey: "userLearningStyle")
        }
    }
    @Published var isConnectedToWatch = false
    @Published var isConnectedToWhoop = false
    @Published var isConnectedToFitbit = false
    
    init() {
        // Load saved state from UserDefaults
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if let savedStyle = UserDefaults.standard.string(forKey: "userLearningStyle"),
           let style = LearningStyle(rawValue: savedStyle) {
            self.userLearningStyle = style
        } else {
            self.userLearningStyle = .visual
        }
    }
    
    func resetAssessment() {
        hasCompletedOnboarding = false
        userLearningStyle = .visual
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "userLearningStyle")
    }
}