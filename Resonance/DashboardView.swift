//
//  DashboardView.swift
//  Resonance
//
//  Created by Claude on 9/3/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @StateObject private var healthKit = HealthKitManager()
    @StateObject private var moodProfile = MoodProfile()
    @State private var showingCrisisSupport = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Main Dashboard with Mood Check-in
                MainDashboard(learningStyle: appState.userLearningStyle, moodProfile: moodProfile)
                    .environmentObject(healthKit)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                
                // Progress Dashboard
                ProgressDashboardView(moodProfile: moodProfile)
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Progress")
                    }
                    .tag(1)
                
                // Daily Wisdom
                DailyWisdomView()
                    .tabItem {
                        Image(systemName: "lightbulb.fill")
                        Text("Wisdom")
                    }
                    .tag(2)
                
                // Health & Devices
                LearningStyleDashboard(learningStyle: appState.userLearningStyle)
                    .environmentObject(healthKit)
                    .tabItem {
                        Image(systemName: "heart.text.square.fill")
                        Text("Health")
                    }
                    .tag(3)
                
                // Settings
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(4)
            }
            .tint(appState.userLearningStyle.color)
            .onAppear {
                healthKit.requestAuthorization()
            }
            .refreshable {
                print("🔄 Manual refresh triggered")
                healthKit.fetchAllHealthData()
            }
            
            // Floating Crisis Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingCrisisSupport = true
                        let haptic = UINotificationFeedbackGenerator()
                        haptic.notificationOccurred(.warning)
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 60, height: 60)
                                .shadow(color: .red.opacity(0.3), radius: 10, y: 5)
                            
                            Image(systemName: "heart.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90) // Above tab bar
                }
            }
        }
        .sheet(isPresented: $showingCrisisSupport) {
            CrisisSupportView()
        }
    }
}

struct LearningStyleDashboard: View {
    let learningStyle: LearningStyle
    @EnvironmentObject var healthKit: HealthKitManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    HeaderView(learningStyle: learningStyle)
                    
                    // Debug Data Card
                    DebugDataCard()
                    
                    switch learningStyle {
                    case .visual:
                        VisualDashboard()
                    case .auditory:
                        AuditoryDashboard()
                    case .kinesthetic:
                        KinestheticDashboard()
                    }
                }
                .padding()
            }
            .navigationTitle("Resonance")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct HeaderView: View {
    let learningStyle: LearningStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Good morning!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(learningStyle.rawValue) Dashboard")
                        .font(.subheadline)
                        .foregroundColor(learningStyle.color)
                }
                
                Spacer()
                
                // Stress level indicator
                VStack {
                    Text("Stress Level")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { level in
                            Circle()
                                .fill(level <= 3 ? learningStyle.color : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(learningStyle.color.opacity(0.1))
        .cornerRadius(15)
    }
}

struct VisualDashboard: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            VisualMetricCard(title: "Heart Rate", value: "72", unit: "BPM", color: .red)
            VisualMetricCard(title: "Steps", value: "8,432", unit: "today", color: .green)
            VisualMetricCard(title: "Sleep", value: "7h 23m", unit: "last night", color: .blue)
            VisualMetricCard(title: "HRV", value: "45", unit: "ms", color: .purple)
        }
        
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Stress Trend")
                .font(.headline)
                .padding(.horizontal)
            
            // Simple chart placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.visualPurple.opacity(0.1))
                .frame(height: 150)
                .overlay(
                    Text("Visual stress trend chart\n(Chart implementation would go here)")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                )
        }
    }
}

struct AuditoryDashboard: View {
    var body: some View {
        VStack(spacing: 20) {
            // Audio-focused metrics
            HStack(spacing: 15) {
                AudioMetricItem(icon: "waveform", title: "Voice Stress", value: "Low", color: .auditoryTeal)
                AudioMetricItem(icon: "heart.fill", title: "HR Zone", value: "Rest", color: .red)
            }
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Today's Audio Summary")
                    .font(.headline)
                
                VStack(spacing: 10) {
                    AudioSummaryRow(label: "Stress Level", value: "Moderate", description: "Based on voice analysis")
                    AudioSummaryRow(label: "Recovery", value: "Good", description: "HRV indicates good recovery")
                    AudioSummaryRow(label: "Energy", value: "High", description: "Active throughout the day")
                }
                .padding()
                .background(Color.auditoryTeal.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Recommended audio content
            VStack(alignment: .leading, spacing: 10) {
                Text("Recommended for You")
                    .font(.headline)
                
                RecommendedAudioCard(title: "Stress Relief Meditation", duration: "10 min", type: "Meditation")
                RecommendedAudioCard(title: "Focus Sounds", duration: "30 min", type: "Ambient")
            }
        }
    }
}

struct KinestheticDashboard: View {
    var body: some View {
        VStack(spacing: 20) {
            // Movement-focused metrics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                MovementCard(title: "Active Minutes", value: "127", subtitle: "Goal: 150", progress: 0.85)
                MovementCard(title: "Calories", value: "2,145", subtitle: "Goal: 2,200", progress: 0.97)
            }
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Movement Recommendations")
                    .font(.headline)
                
                VStack(spacing: 10) {
                    MovementRecommendation(
                        icon: "figure.walk",
                        title: "Take a Walk",
                        description: "5 minutes to reduce stress",
                        urgency: .medium
                    )
                    
                    MovementRecommendation(
                        icon: "figure.strengthtraining.traditional",
                        title: "Desk Stretches",
                        description: "Your shoulders need attention",
                        urgency: .high
                    )
                    
                    MovementRecommendation(
                        icon: "figure.mind.and.body",
                        title: "Deep Breathing",
                        description: "3 minutes of focused breathing",
                        urgency: .low
                    )
                }
            }
        }
    }
}

// MARK: - Visual Components
struct VisualMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    var isLive: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

// MARK: - Auditory Components
struct AudioMetricItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct AudioSummaryRow: View {
    let label: String
    let value: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.auditoryTeal)
        }
    }
}

struct RecommendedAudioCard: View {
    let title: String
    let duration: String
    let type: String
    
    var body: some View {
        HStack {
            Image(systemName: "play.circle.fill")
                .foregroundColor(.auditoryTeal)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(type) • \(duration)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Kinesthetic Components
struct MovementCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.kinestheticOrange)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
            
            ProgressView(value: progress)
                .tint(.kinestheticOrange)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct MovementRecommendation: View {
    let icon: String
    let title: String
    let description: String
    let urgency: RecommendationUrgency
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(urgency.color)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Circle()
                .fill(urgency.color)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

enum RecommendationUrgency {
    case low, medium, high
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Device Connection View
struct DeviceConnectionView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            List {
                Section("Wearable Devices") {
                    DeviceRow(
                        name: "Apple Watch",
                        icon: "applewatch",
                        isConnected: appState.isConnectedToWatch,
                        onToggle: { appState.isConnectedToWatch.toggle() }
                    )
                    
                    DeviceRow(
                        name: "Whoop",
                        icon: "waveform.path.ecg",
                        isConnected: appState.isConnectedToWhoop,
                        onToggle: { appState.isConnectedToWhoop.toggle() }
                    )
                    
                    DeviceRow(
                        name: "Fitbit",
                        icon: "heart.circle",
                        isConnected: appState.isConnectedToFitbit,
                        onToggle: { appState.isConnectedToFitbit.toggle() }
                    )
                }
                
                Section("Data Sync") {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                        Text("Last sync: 5 minutes ago")
                        Spacer()
                    }
                }
            }
            .navigationTitle("Devices")
        }
    }
}

struct DeviceRow: View {
    let name: String
    let icon: String
    let isConnected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isConnected ? .green : .gray)
                .frame(width: 24)
            
            Text(name)
            
            Spacer()
            
            Text(isConnected ? "Connected" : "Not Connected")
                .font(.caption)
                .foregroundColor(isConnected ? .green : .gray)
            
            Button(isConnected ? "Disconnect" : "Connect") {
                onToggle()
            }
            .buttonStyle(.borderless)
            .foregroundColor(.blue)
        }
    }
}

// MARK: - Debug Data Card
struct DebugDataCard: View {
    @EnvironmentObject var healthKit: HealthKitManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("📱 Live Health Data")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Steps Today:")
                    Spacer()
                    Text("\(healthKit.todaysSteps)")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Heart Rate:")
                    Spacer()
                    Text(healthKit.currentHeartRate > 0 ? "\(Int(healthKit.currentHeartRate)) bpm" : "No data")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("HRV:")
                    Spacer()
                    Text(healthKit.latestHRV > 0 ? "\(Int(healthKit.latestHRV)) ms" : "No data")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Sleep:")
                    Spacer()
                    Text(healthKit.sleepHours > 0 ? String(format: "%.1f hours", healthKit.sleepHours) : "No data")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Active Calories:")
                    Spacer()
                    Text("\(healthKit.activeCalories) cal")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Last Updated:")
                    Spacer()
                    Text(Date().formatted(date: .omitted, time: .standard))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .font(.system(size: 14))
            
            Button(action: {
                print("🔄 Manual refresh from debug card")
                healthKit.fetchAllHealthData()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Data")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAssessmentAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Learning Style") {
                    HStack {
                        Text("Current Style")
                        Spacer()
                        Text(appState.userLearningStyle.rawValue)
                            .foregroundColor(appState.userLearningStyle.color)
                    }
                    
                    Button(action: {
                        showingAssessmentAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(appState.userLearningStyle.color)
                            Text("Retake Assessment")
                        }
                    }
                }
                
                Section("Notifications") {
                    Toggle("Stress Alerts", isOn: .constant(true))
                    Toggle("Movement Reminders", isOn: .constant(true))
                    Toggle("Recovery Insights", isOn: .constant(false))
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Retake Assessment?", isPresented: $showingAssessmentAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Retake", role: .destructive) {
                    appState.resetAssessment()
                }
            } message: {
                Text("This will reset your learning style preference and show the assessment questions again.")
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}