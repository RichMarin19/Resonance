import SwiftUI
import Charts

struct ProgressDashboardView: View {
    @ObservedObject var moodProfile: MoodProfile
    @State private var selectedTimeRange = TimeRange.week
    @State private var showingCelebration = false
    
    init(moodProfile: MoodProfile? = nil) {
        self._moodProfile = ObservedObject(wrappedValue: moodProfile ?? MoodProfile())
    }
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return 365
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with streak
                StreakHeaderCard(streak: moodProfile.streak)
                    .onTapGesture {
                        if moodProfile.streak.currentStreak > 0 {
                            showingCelebration = true
                            triggerHaptic(.success)
                        }
                    }
                
                // Mood trend chart
                MoodTrendCard(
                    moodData: moodProfile.getMoodTrend(days: selectedTimeRange.days),
                    timeRange: $selectedTimeRange
                )
                
                // Statistics grid
                StatsGrid(
                    averageMood: moodProfile.getAverageMood(days: selectedTimeRange.days),
                    totalEntries: moodProfile.getRecentMood(days: selectedTimeRange.days).count,
                    insight: moodProfile.generateInsight()
                )
                
                // Recent moods list
                RecentMoodsCard(entries: moodProfile.getRecentMood(days: 7))
                
                // Achievement badges
                AchievementSection(moodProfile: moodProfile)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .overlay(
            CelebrationView(isShowing: $showingCelebration)
        )
    }
    
    private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

struct StreakHeaderCard: View {
    let streak: MoodStreak
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Streak")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(streak.currentStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("days")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    if streak.currentStreak > 2 {
                        Text("🔥")
                            .font(.system(size: 32))
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                            .onAppear { isAnimating = true }
                    }
                }
                
                if streak.longestStreak > streak.currentStreak {
                    Text("Best: \(streak.longestStreak) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Visual streak indicator
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: min(1.0, CGFloat(streak.currentStreak) / 30.0))
                    .stroke(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5), value: streak.currentStreak)
                
                VStack(spacing: 0) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("\(Int(min(100, CGFloat(streak.currentStreak) / 30.0 * 100)))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

struct MoodTrendCard: View {
    let moodData: [Double]
    @Binding var timeRange: ProgressDashboardView.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Mood Trend")
                    .font(.headline)
                
                Spacer()
                
                Picker("Time Range", selection: $timeRange) {
                    ForEach(ProgressDashboardView.TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            if !moodData.isEmpty {
                Chart {
                    ForEach(Array(moodData.enumerated()), id: \.offset) { index, value in
                        if value > 0 {
                            LineMark(
                                x: .value("Day", index),
                                y: .value("Mood", value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            
                            AreaMark(
                                x: .value("Day", index),
                                y: .value("Mood", value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            
                            PointMark(
                                x: .value("Day", index),
                                y: .value("Mood", value)
                            )
                            .foregroundStyle(Color.white)
                            .symbolSize(60)
                        }
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...10)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                Text("Start tracking your mood to see trends")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

struct StatsGrid: View {
    let averageMood: Double
    let totalEntries: Int
    let insight: String
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "Average Mood",
                value: String(format: "%.1f", averageMood),
                icon: "face.smiling",
                color: Color(hue: 0.3 * (averageMood / 10.0), saturation: 0.5, brightness: 0.9)
            )
            
            StatCard(
                title: "Total Check-ins",
                value: "\(totalEntries)",
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
        
        InsightCard(insight: insight)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

struct InsightCard: View {
    let insight: String
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundColor(.yellow)
            
            Text(insight)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

struct RecentMoodsCard: View {
    let entries: [MoodEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Moods")
                .font(.headline)
            
            if entries.isEmpty {
                Text("No moods tracked yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(entries.prefix(5)) { entry in
                        HStack {
                            Text(entry.emoji)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.timestamp, style: .relative)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                if let tag = entry.tag {
                                    Text(tag.rawValue)
                                        .font(.caption)
                                        .foregroundColor(tag.color)
                                }
                            }
                            
                            Spacer()
                            
                            Text(String(format: "%.0f", entry.value))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(entry.color)
                        }
                        .padding(.vertical, 8)
                        
                        if entry.id != entries.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

struct AchievementSection: View {
    @ObservedObject var moodProfile: MoodProfile
    
    var achievements: [(String, String, Bool)] {
        [
            ("First Check-in", "checkmark.circle.fill", moodProfile.entries.count >= 1),
            ("Week Warrior", "calendar.badge.plus", moodProfile.streak.currentStreak >= 7),
            ("Mood Master", "star.fill", moodProfile.streak.currentStreak >= 30),
            ("Consistent", "arrow.clockwise", moodProfile.entries.count >= 20),
            ("Insightful", "brain", moodProfile.entries.filter { $0.note != nil }.count >= 5)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                ForEach(achievements, id: \.0) { achievement in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(achievement.2 ? Color.yellow.opacity(0.2) : Color(.systemGray6))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: achievement.1)
                                .font(.title2)
                                .foregroundColor(achievement.2 ? .yellow : .gray)
                        }
                        
                        Text(achievement.0)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(achievement.2 ? .primary : .secondary)
                    }
                    .scaleEffect(achievement.2 ? 1.0 : 0.9)
                    .opacity(achievement.2 ? 1.0 : 0.6)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

struct CelebrationView: View {
    @Binding var isShowing: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        if isShowing {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissCelebration()
                    }
                
                VStack(spacing: 20) {
                    Text("🎉")
                        .font(.system(size: 80))
                    
                    Text("Amazing Streak!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Keep up the great work!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                )
                .scaleEffect(scale)
                .opacity(opacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    scale = 1.0
                    opacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismissCelebration()
                }
            }
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 0.5
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}

#Preview {
    ProgressDashboardView()
}