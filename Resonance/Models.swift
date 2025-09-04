//
//  Models.swift
//  Resonance
//
//  Created by Claude on 9/3/25.
//

import SwiftUI
import Foundation

// MARK: - Learning Style Model
enum LearningStyle: String, CaseIterable {
    case visual = "Visual"
    case auditory = "Auditory"
    case kinesthetic = "Kinesthetic"
    
    var color: Color {
        switch self {
        case .visual:
            return .visualPurple
        case .auditory:
            return .auditoryTeal
        case .kinesthetic:
            return .kinestheticOrange
        }
    }
    
    var description: String {
        switch self {
        case .visual:
            return "You learn best through visual elements like charts, graphs, and organized displays. Your dashboard emphasizes clear visual representations of your health data."
        case .auditory:
            return "You process information best through listening and verbal communication. Your dashboard focuses on audio feedback and spoken insights about your health."
        case .kinesthetic:
            return "You learn through hands-on experience and physical interaction. Your dashboard emphasizes movement, tactile feedback, and actionable recommendations."
        }
    }
}

// MARK: - Health Data Models
struct HealthMetric {
    let id = UUID()
    let name: String
    let value: Double
    let unit: String
    let category: HealthCategory
    let timestamp: Date
    let source: DataSource
}

enum HealthCategory {
    case heartRate
    case steps
    case sleep
    case stress
    case hrv
    case calories
    case activeMinutes
    case recovery
}

enum DataSource {
    case appleWatch
    case whoop
    case fitbit
    case manual
    
    var displayName: String {
        switch self {
        case .appleWatch:
            return "Apple Watch"
        case .whoop:
            return "Whoop"
        case .fitbit:
            return "Fitbit"
        case .manual:
            return "Manual Entry"
        }
    }
    
    var icon: String {
        switch self {
        case .appleWatch:
            return "applewatch"
        case .whoop:
            return "waveform.path.ecg"
        case .fitbit:
            return "heart.circle"
        case .manual:
            return "hand.tap"
        }
    }
}

// MARK: - Stress Analysis Models
struct StressLevel {
    let value: Int // 1-5 scale
    let timestamp: Date
    let factors: [StressFactor]
    let recommendations: [StressRecommendation]
}

enum StressFactor {
    case workload
    case sleep
    case heartRateVariability
    case physicalActivity
    case voiceAnalysis
    case userReported
    
    var description: String {
        switch self {
        case .workload:
            return "Work-related stress detected"
        case .sleep:
            return "Poor sleep quality affecting stress"
        case .heartRateVariability:
            return "Low HRV indicates stress"
        case .physicalActivity:
            return "Lack of physical activity"
        case .voiceAnalysis:
            return "Voice stress indicators"
        case .userReported:
            return "Self-reported stress"
        }
    }
}

struct StressRecommendation {
    let id = UUID()
    let title: String
    let description: String
    let duration: TimeInterval
    let type: RecommendationType
    let urgency: RecommendationUrgency
    
    enum RecommendationType {
        case breathing
        case movement
        case meditation
        case `break`
        case hydration
        case audio
        
        var icon: String {
            switch self {
            case .breathing:
                return "wind"
            case .movement:
                return "figure.walk"
            case .meditation:
                return "leaf"
            case .break:
                return "pause"
            case .hydration:
                return "drop"
            case .audio:
                return "speaker.wave.2"
            }
        }
    }
}

// MARK: - User Profile Models
struct UserProfile {
    var id = UUID()
    var learningStyle: LearningStyle
    var profession: String?
    var stressGoals: [StressGoal]
    var deviceConnections: DeviceConnections
    var preferences: UserPreferences
}

struct StressGoal {
    let id = UUID()
    let title: String
    let targetValue: Double
    let currentValue: Double
    let deadline: Date?
    let category: HealthCategory
}

struct DeviceConnections {
    var appleWatch: DeviceConnection?
    var whoop: DeviceConnection?
    var fitbit: DeviceConnection?
}

struct DeviceConnection {
    let deviceId: String
    let isConnected: Bool
    let lastSync: Date?
    let permissions: [HealthPermission]
}

enum HealthPermission {
    case heartRate
    case steps
    case sleep
    case workouts
    case hrv
    case stress
    case calories
}

struct UserPreferences {
    var notificationsEnabled: Bool = true
    var stressAlertsEnabled: Bool = true
    var movementRemindersEnabled: Bool = true
    var recoveryInsightsEnabled: Bool = true
    var dashboardRefreshInterval: TimeInterval = 300 // 5 minutes
    var preferredUnits: UnitPreferences = UnitPreferences()
}

struct UnitPreferences {
    var distance: DistanceUnit = .miles
    var weight: WeightUnit = .pounds
    var temperature: TemperatureUnit = .fahrenheit
    
    enum DistanceUnit {
        case miles, kilometers
    }
    
    enum WeightUnit {
        case pounds, kilograms
    }
    
    enum TemperatureUnit {
        case fahrenheit, celsius
    }
}

// MARK: - Analytics Models
struct HealthAnalytics {
    let dailyTrends: [DailyTrend]
    let weeklyInsights: [WeeklyInsight]
    let monthlyReport: MonthlyReport?
}

struct DailyTrend {
    let date: Date
    let stressLevel: Double
    let heartRate: Double
    let steps: Int
    let sleepHours: Double
    let activeMinutes: Int
}

struct WeeklyInsight {
    let weekStart: Date
    let insight: String
    let category: HealthCategory
    let improvement: Double // percentage change
}

struct MonthlyReport {
    let month: Date
    let overallStressReduction: Double
    let goalProgress: [GoalProgress]
    let achievements: [Achievement]
}

struct GoalProgress {
    let goal: StressGoal
    let progress: Double // 0.0 to 1.0
    let onTrack: Bool
}

struct Achievement {
    let id = UUID()
    let title: String
    let description: String
    let dateEarned: Date
    let icon: String
    let category: AchievementCategory
}

enum AchievementCategory {
    case stressReduction
    case consistency
    case movement
    case sleep
    case recovery
    
    var color: Color {
        switch self {
        case .stressReduction:
            return .blue
        case .consistency:
            return .green
        case .movement:
            return .orange
        case .sleep:
            return .purple
        case .recovery:
            return .teal
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static let primaryBlue = Color(red: 0.0, green: 0.478, blue: 1.0) // #007AFF
    static let visualPurple = Color(red: 0.345, green: 0.337, blue: 0.839) // #5856D6
    static let auditoryTeal = Color(red: 0.353, green: 0.784, blue: 0.980) // #5AC8FA
    static let kinestheticOrange = Color(red: 1.0, green: 0.420, blue: 0.208) // #FF6B35
}

// MARK: - Sample Data (for development/preview purposes)
extension UserProfile {
    static let sample = UserProfile(
        learningStyle: .visual,
        profession: "Software Developer",
        stressGoals: [
            StressGoal(
                title: "Reduce daily stress",
                targetValue: 2.0,
                currentValue: 3.5,
                deadline: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
                category: .stress
            )
        ],
        deviceConnections: DeviceConnections(),
        preferences: UserPreferences()
    )
}

extension HealthMetric {
    static let sampleMetrics: [HealthMetric] = [
        HealthMetric(
            name: "Heart Rate",
            value: 72,
            unit: "BPM",
            category: .heartRate,
            timestamp: Date(),
            source: .appleWatch
        ),
        HealthMetric(
            name: "Steps",
            value: 8432,
            unit: "steps",
            category: .steps,
            timestamp: Date(),
            source: .appleWatch
        ),
        HealthMetric(
            name: "Sleep",
            value: 7.38,
            unit: "hours",
            category: .sleep,
            timestamp: Date(),
            source: .appleWatch
        )
    ]
}

extension StressRecommendation {
    static let sampleRecommendations: [StressRecommendation] = [
        StressRecommendation(
            title: "Take a Deep Breath",
            description: "5 minutes of focused breathing to reduce stress",
            duration: 300,
            type: .breathing,
            urgency: .medium
        ),
        StressRecommendation(
            title: "Quick Walk",
            description: "Step away from your desk for a brief walk",
            duration: 600,
            type: .movement,
            urgency: .high
        ),
        StressRecommendation(
            title: "Mindful Moment",
            description: "Brief meditation to center yourself",
            duration: 180,
            type: .meditation,
            urgency: .low
        )
    ]
}
