import Foundation
import SwiftUI

// MARK: - Activity Entry
struct ActivityEntry: Identifiable, Codable {
    var id = UUID()
    let timestamp: Date
    let type: ActivityType
    let customName: String? // For "Other" activities
    let duration: TimeInterval // in seconds
    let heartRateAvg: Double?
    let heartRateMax: Double?
    let heartRateMin: Double?
    let calories: Double?
    let distance: Double? // in meters
    let steps: Int?
    let notes: String?
    let moodBefore: Double?
    let moodAfter: Double?
    
    var displayName: String {
        if type == .other {
            return customName ?? "Activity"
        }
        return type.rawValue
    }
    
    var formattedDuration: String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

// MARK: - Activity Type
enum ActivityType: String, CaseIterable, Codable {
    // Visual activities
    case breathe = "Breathe"
    case journal = "Journal"
    case meditate = "Meditate"
    case exercise = "Exercise"
    
    // Auditory activities
    case music = "Music"
    case podcast = "Podcast"
    case callFriend = "Call Friend"
    case voiceNote = "Voice Note"
    
    // Kinesthetic activities
    case walk = "Walk"
    case stretch = "Stretch"
    case dance = "Dance"
    case workout = "Workout"
    
    // Custom
    case other = "Other"
    
    var icon: String {
        switch self {
        case .breathe: return "wind"
        case .journal: return "book.fill"
        case .meditate: return "brain.head.profile"
        case .exercise: return "figure.run"
        case .music: return "music.note"
        case .podcast: return "mic.fill"
        case .callFriend: return "phone.fill"
        case .voiceNote: return "waveform"
        case .walk: return "figure.walk"
        case .stretch: return "figure.flexibility"
        case .dance: return "music.note.house"
        case .workout: return "dumbbell.fill"
        case .other: return "plus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breathe: return .mint
        case .journal: return .blue
        case .meditate: return .purple
        case .exercise: return .orange
        case .music: return .pink
        case .podcast: return .blue
        case .callFriend: return .green
        case .voiceNote: return .orange
        case .walk: return .green
        case .stretch: return .blue
        case .dance: return .purple
        case .workout: return .orange
        case .other: return .gray
        }
    }
    
    var suggestedDuration: TimeInterval {
        switch self {
        case .breathe: return 180 // 3 minutes
        case .journal: return 300 // 5 minutes
        case .meditate: return 600 // 10 minutes
        case .exercise: return 1800 // 30 minutes
        case .music: return 900 // 15 minutes
        case .podcast: return 1800 // 30 minutes
        case .callFriend: return 600 // 10 minutes
        case .voiceNote: return 120 // 2 minutes
        case .walk: return 900 // 15 minutes
        case .stretch: return 300 // 5 minutes
        case .dance: return 600 // 10 minutes
        case .workout: return 2700 // 45 minutes
        case .other: return 600 // 10 minutes default
        }
    }
}

// MARK: - Activity Manager
// MARK: - Real-time Activity Data
struct ActivityDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let heartRate: Double?
    let distance: Double?
    let pace: Double? // meters per second
}

class ActivityManager: ObservableObject {
    @Published var activities: [ActivityEntry] = []
    @Published var currentActivity: ActivityEntry?
    @Published var isTracking = false
    @Published var activityStartTime: Date?
    @Published var activityHeartRates: [Double] = []
    @Published var activityDataPoints: [ActivityDataPoint] = []
    @Published var currentDistance: Double = 0 // meters
    @Published var currentSteps: Int = 0
    @Published var currentPace: Double = 0 // min/km
    @Published var currentHeartRate: Double = 0
    
    private let saveKey = "activityEntries"
    var startSteps: Int = 0
    var startDistance: Double = 0
    
    init() {
        loadActivities()
    }
    
    func startActivity(type: ActivityType, customName: String? = nil, moodBefore: Double? = nil, initialSteps: Int = 0, initialDistance: Double = 0) {
        activityStartTime = Date()
        activityHeartRates = []
        activityDataPoints = []
        isTracking = true
        
        // Reset tracking values
        currentDistance = 0
        currentSteps = 0
        currentPace = 0
        currentHeartRate = 0
        startSteps = initialSteps
        startDistance = initialDistance
        
        // Create a temporary activity entry
        currentActivity = ActivityEntry(
            timestamp: activityStartTime!,
            type: type,
            customName: customName,
            duration: 0,
            heartRateAvg: nil,
            heartRateMax: nil,
            heartRateMin: nil,
            calories: nil,
            distance: nil,
            steps: nil,
            notes: nil,
            moodBefore: moodBefore,
            moodAfter: nil
        )
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    func stopActivity(moodAfter: Double? = nil, notes: String? = nil) {
        guard let startTime = activityStartTime, let activity = currentActivity else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Calculate heart rate stats if available
        var hrAvg: Double? = nil
        var hrMax: Double? = nil
        var hrMin: Double? = nil
        
        if !activityHeartRates.isEmpty {
            hrAvg = activityHeartRates.reduce(0, +) / Double(activityHeartRates.count)
            hrMax = activityHeartRates.max()
            hrMin = activityHeartRates.min()
        }
        
        // Create final activity entry
        let finalActivity = ActivityEntry(
            timestamp: startTime,
            type: activity.type,
            customName: activity.customName,
            duration: duration,
            heartRateAvg: hrAvg,
            heartRateMax: hrMax,
            heartRateMin: hrMin,
            calories: estimateCalories(type: activity.type, duration: duration, avgHR: hrAvg),
            distance: currentDistance > 0 ? currentDistance : nil,
            steps: currentSteps > 0 ? currentSteps : nil,
            notes: notes,
            moodBefore: activity.moodBefore,
            moodAfter: moodAfter
        )
        
        activities.append(finalActivity)
        saveActivities()
        
        // Reset tracking state
        isTracking = false
        currentActivity = nil
        activityStartTime = nil
        activityHeartRates = []
        
        // Success haptic
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
    
    func addHeartRate(_ heartRate: Double) {
        activityHeartRates.append(heartRate)
        currentHeartRate = heartRate
    }
    
    func updateActivityData(heartRate: Double? = nil, steps: Int? = nil, distance: Double? = nil) {
        // Update current values
        if let hr = heartRate {
            currentHeartRate = hr
            activityHeartRates.append(hr)
        }
        
        if let s = steps {
            currentSteps = s - startSteps
        }
        
        if let d = distance {
            currentDistance = d - startDistance
            
            // Calculate pace (min/km)
            if let startTime = activityStartTime, currentDistance > 0 {
                let elapsedMinutes = Date().timeIntervalSince(startTime) / 60
                let distanceKm = currentDistance / 1000
                if distanceKm > 0 {
                    currentPace = elapsedMinutes / distanceKm
                }
            }
        }
        
        // Add data point for graph
        let dataPoint = ActivityDataPoint(
            timestamp: Date(),
            heartRate: heartRate,
            distance: currentDistance > 0 ? currentDistance : nil,
            pace: currentPace > 0 ? currentPace : nil
        )
        activityDataPoints.append(dataPoint)
        
        // Keep only last 100 data points for performance
        if activityDataPoints.count > 100 {
            activityDataPoints.removeFirst()
        }
    }
    
    func cancelActivity() {
        isTracking = false
        currentActivity = nil
        activityStartTime = nil
        activityHeartRates = []
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func estimateCalories(type: ActivityType, duration: TimeInterval, avgHR: Double?) -> Double {
        // Simple calorie estimation based on activity type and duration
        let minutesDuration = duration / 60
        
        let baseCaloriesPerMinute: Double = {
            switch type {
            case .breathe, .meditate: return 1.5
            case .journal, .voiceNote: return 1.8
            case .music, .podcast: return 1.2
            case .callFriend: return 1.5
            case .walk: return 4.0
            case .stretch: return 2.5
            case .dance: return 6.0
            case .exercise, .workout: return 8.0
            case .other: return 3.0
            }
        }()
        
        // Adjust based on heart rate if available
        var multiplier = 1.0
        if let hr = avgHR {
            if hr > 140 { multiplier = 1.5 }
            else if hr > 120 { multiplier = 1.3 }
            else if hr > 100 { multiplier = 1.1 }
        }
        
        return baseCaloriesPerMinute * minutesDuration * multiplier
    }
    
    func getRecentActivities(days: Int = 7) -> [ActivityEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return activities.filter { $0.timestamp >= cutoff }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    func getTodaysActivities() -> [ActivityEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return activities.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    func getActivityStats(for type: ActivityType, days: Int = 30) -> (count: Int, totalDuration: TimeInterval, avgDuration: TimeInterval) {
        let recent = getRecentActivities(days: days).filter { $0.type == type }
        let count = recent.count
        let totalDuration = recent.reduce(0) { $0 + $1.duration }
        let avgDuration = count > 0 ? totalDuration / Double(count) : 0
        return (count, totalDuration, avgDuration)
    }
    
    private func loadActivities() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([ActivityEntry].self, from: data) {
            activities = decoded
        }
    }
    
    private func saveActivities() {
        if let encoded = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
}