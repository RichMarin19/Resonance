import Foundation
import SwiftUI

// MARK: - Mood Entry
struct MoodEntry: Identifiable, Codable {
    var id = UUID()
    let timestamp: Date
    let value: Double // 1-10 scale
    var tag: MoodTag?
    var note: String?
    
    var emoji: String {
        switch value {
        case 0..<2: return "😔"
        case 2..<4: return "😕"
        case 4..<6: return "😐"
        case 6..<8: return "🙂"
        case 8...10: return "😊"
        default: return "😐"
        }
    }
    
    var color: Color {
        // Gradient from cool to warm based on mood
        let hue = 0.3 * (value / 10.0) // 0 = blue-purple, 0.3 = green
        return Color(hue: hue, saturation: 0.5, brightness: 0.9)
    }
}

// MARK: - Mood Tags
enum MoodTag: String, CaseIterable, Codable {
    case work = "Work"
    case relationship = "Relationship"
    case health = "Health"
    case sleep = "Sleep"
    case family = "Family"
    case money = "Money"
    case general = "General"
    
    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .relationship: return "heart.fill"
        case .health: return "heart.text.square.fill"
        case .sleep: return "moon.fill"
        case .family: return "person.2.fill"
        case .money: return "dollarsign.circle.fill"
        case .general: return "circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .work: return .blue
        case .relationship: return .pink
        case .health: return .green
        case .sleep: return .purple
        case .family: return .orange
        case .money: return .mint
        case .general: return .gray
        }
    }
}

// MARK: - Streak Tracking
struct MoodStreak: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastCheckIn: Date?
    
    mutating func updateStreak(for date: Date) {
        if let last = lastCheckIn {
            let calendar = Calendar.current
            let daysBetween = calendar.dateComponents([.day], from: last, to: date).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day
                currentStreak += 1
                longestStreak = max(currentStreak, longestStreak)
            } else if daysBetween > 1 {
                // Streak broken
                currentStreak = 1
            }
            // If daysBetween == 0, same day, don't change streak
        } else {
            // First check-in
            currentStreak = 1
            longestStreak = 1
        }
        lastCheckIn = date
    }
}

// MARK: - Daily Insight
struct DailyWisdom: Identifiable, Codable {
    var id = UUID()
    let content: String
    let category: WisdomCategory
    let source: String?
    var isFavorite: Bool = false
    var dateShown: Date = Date()
    
    enum WisdomCategory: String, Codable {
        case cbt = "CBT"
        case dbt = "DBT"
        case mindfulness = "Mindfulness"
        case motivation = "Motivation"
        case grounding = "Grounding"
    }
}

// MARK: - Crisis Resources
struct CrisisResource {
    let title: String
    let action: CrisisAction
    let icon: String
    let color: Color
    
    enum CrisisAction {
        case call(number: String)
        case text(number: String, message: String)
        case exercise(type: GroundingExercise)
        case breathe
        
        enum GroundingExercise {
            case fiveFourThreeTwoOne
            case boxBreathing
            case muscleRelaxation
        }
    }
}

// MARK: - User Mood Profile
class MoodProfile: ObservableObject {
    @Published var entries: [MoodEntry] = []
    @Published var streak = MoodStreak()
    @Published var favoriteWisdoms: [DailyWisdom] = []
    
    private let saveKey = "moodEntries"
    private let streakKey = "moodStreak"
    
    init() {
        loadData()
    }
    
    func addEntry(_ entry: MoodEntry) {
        entries.append(entry)
        streak.updateStreak(for: entry.timestamp)
        saveData()
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    func getRecentMood(days: Int = 7) -> [MoodEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { $0.timestamp >= cutoff }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    func getAverageMood(days: Int = 7) -> Double {
        let recent = getRecentMood(days: days)
        guard !recent.isEmpty else { return 5.0 }
        let sum = recent.reduce(0) { $0 + $1.value }
        return sum / Double(recent.count)
    }
    
    func getMoodTrend(days: Int = 7) -> [Double] {
        let recent = getRecentMood(days: days)
        var dailyAverages: [Date: [Double]] = [:]
        
        let calendar = Calendar.current
        for entry in recent {
            let day = calendar.startOfDay(for: entry.timestamp)
            if dailyAverages[day] == nil {
                dailyAverages[day] = []
            }
            dailyAverages[day]?.append(entry.value)
        }
        
        // Create array for last 7 days
        var trend: [Double] = []
        for i in (0..<days).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let dayStart = calendar.startOfDay(for: date)
                if let values = dailyAverages[dayStart], !values.isEmpty {
                    trend.append(values.reduce(0, +) / Double(values.count))
                } else {
                    trend.append(0) // No data for this day
                }
            }
        }
        
        return trend
    }
    
    func generateInsight() -> String {
        let recent = getRecentMood(days: 7)
        guard recent.count > 3 else {
            return "Check in daily to see your patterns"
        }
        
        // Find most common tag
        let tags = recent.compactMap { $0.tag }
        let tagCounts = Dictionary(grouping: tags, by: { $0 }).mapValues { $0.count }
        if let mostCommon = tagCounts.max(by: { $0.value < $1.value })?.key {
            return "Your mood is most affected by \(mostCommon.rawValue.lowercased()) this week"
        }
        
        // Check for patterns
        let morningMoods = recent.filter { 
            Calendar.current.component(.hour, from: $0.timestamp) < 12 
        }
        let eveningMoods = recent.filter { 
            Calendar.current.component(.hour, from: $0.timestamp) >= 18 
        }
        
        if !morningMoods.isEmpty && !eveningMoods.isEmpty {
            let morningAvg = morningMoods.reduce(0) { $0 + $1.value } / Double(morningMoods.count)
            let eveningAvg = eveningMoods.reduce(0) { $0 + $1.value } / Double(eveningMoods.count)
            
            if morningAvg > eveningAvg + 1 {
                return "You tend to feel better in the mornings"
            } else if eveningAvg > morningAvg + 1 {
                return "Your mood improves throughout the day"
            }
        }
        
        // Trend analysis
        let trend = getMoodTrend(days: 7)
        if trend.count >= 3 {
            let recentAvg = trend.suffix(3).reduce(0, +) / 3
            let olderAvg = trend.prefix(3).reduce(0, +) / 3
            
            if recentAvg > olderAvg + 0.5 {
                return "Your mood is trending upward! 📈"
            } else if olderAvg > recentAvg + 0.5 {
                return "Take extra care of yourself today"
            }
        }
        
        return "You're building great tracking habits!"
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            entries = decoded
        }
        
        if let streakData = UserDefaults.standard.data(forKey: streakKey),
           let decodedStreak = try? JSONDecoder().decode(MoodStreak.self, from: streakData) {
            streak = decodedStreak
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
        
        if let streakEncoded = try? JSONEncoder().encode(streak) {
            UserDefaults.standard.set(streakEncoded, forKey: streakKey)
        }
    }
}