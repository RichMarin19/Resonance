import SwiftUI
import Charts

struct SummaryView: View {
    @ObservedObject var healthKit: HealthKitManager
    @ObservedObject var moodProfile: MoodProfile
    @StateObject private var activityManager = ActivityManager()
    @State private var selectedPeriod = TimePeriod.week
    @Environment(\.dismiss) var dismiss
    
    enum TimePeriod: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case quarter = "90 Days"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Period Selector
                    Picker("Time Period", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Overall Stats
                    OverallStatsCard(
                        period: selectedPeriod,
                        healthKit: healthKit,
                        moodProfile: moodProfile,
                        activityManager: activityManager
                    )
                    
                    // Mood Trend Chart
                    MoodTrendChart(
                        moodData: moodProfile.getMoodTrend(days: selectedPeriod.days),
                        period: selectedPeriod
                    )
                    .padding(.horizontal)
                    
                    // Health Metrics Summary
                    HealthMetricsSummary(
                        period: selectedPeriod,
                        healthKit: healthKit
                    )
                    .padding(.horizontal)
                    
                    // Activity Summary
                    ActivitySummaryCard(
                        period: selectedPeriod,
                        activityManager: activityManager
                    )
                    .padding(.horizontal)
                    
                    // Insights
                    InsightsCard(
                        period: selectedPeriod,
                        moodProfile: moodProfile,
                        healthKit: healthKit
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Overall Stats Card
struct OverallStatsCard: View {
    let period: SummaryView.TimePeriod
    @ObservedObject var healthKit: HealthKitManager
    @ObservedObject var moodProfile: MoodProfile
    @ObservedObject var activityManager: ActivityManager
    
    var averageMood: Double {
        moodProfile.getAverageMood(days: period.days)
    }
    
    var totalActivities: Int {
        activityManager.getRecentActivities(days: period.days).count
    }
    
    var averageSteps: Int {
        // This would calculate average from historical data
        healthKit.todaysSteps // Simplified for now
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Overview - Last \(period.rawValue)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                SummaryStatCard(
                    title: "Avg Mood",
                    value: String(format: "%.1f", averageMood),
                    subtitle: "out of 10",
                    icon: "face.smiling",
                    color: Color(hue: 0.3 * (averageMood / 10.0), saturation: 0.5, brightness: 0.9)
                )
                
                SummaryStatCard(
                    title: "Activities",
                    value: "\(totalActivities)",
                    subtitle: "completed",
                    icon: "figure.run",
                    color: .orange
                )
                
                SummaryStatCard(
                    title: "Avg Steps",
                    value: "\(averageSteps)",
                    subtitle: "per day",
                    icon: "figure.walk",
                    color: .green
                )
                
                SummaryStatCard(
                    title: "Streak",
                    value: "\(moodProfile.streak.currentStreak)",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Mood Trend Chart
struct MoodTrendChart: View {
    let moodData: [Double]
    let period: SummaryView.TimePeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Trend")
                .font(.headline)
            
            if !moodData.filter({ $0 > 0 }).isEmpty {
                Chart {
                    ForEach(Array(moodData.enumerated()), id: \.offset) { index, value in
                        if value > 0 {
                            LineMark(
                                x: .value("Day", index),
                                y: .value("Mood", value)
                            )
                            .foregroundStyle(Color.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            
                            AreaMark(
                                x: .value("Day", index),
                                y: .value("Mood", value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            
                            PointMark(
                                x: .value("Day", index),
                                y: .value("Mood", value)
                            )
                            .foregroundStyle(Color.blue)
                            .symbolSize(30)
                        }
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...10)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 5, 10])
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(7, moodData.count)))
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No mood data for this period")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Health Metrics Summary
struct HealthMetricsSummary: View {
    let period: SummaryView.TimePeriod
    @ObservedObject var healthKit: HealthKitManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Metrics")
                .font(.headline)
            
            VStack(spacing: 12) {
                HealthMetricRow(
                    icon: "heart.fill",
                    title: "Avg Heart Rate",
                    value: healthKit.currentHeartRate > 0 ? "\(Int(healthKit.currentHeartRate)) bpm" : "No data",
                    color: .red
                )
                
                HealthMetricRow(
                    icon: "moon.fill",
                    title: "Avg Sleep",
                    value: String(format: "%.1f hrs", healthKit.sleepHours),
                    color: .purple
                )
                
                HealthMetricRow(
                    icon: "waveform.path.ecg",
                    title: "HRV",
                    value: healthKit.latestHRV > 0 ? String(format: "%.0f ms", healthKit.latestHRV) : "No data",
                    color: .green
                )
                
                HealthMetricRow(
                    icon: "flame.fill",
                    title: "Active Calories",
                    value: "\(healthKit.activeCalories) cal",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct HealthMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Activity Summary
struct ActivitySummaryCard: View {
    let period: SummaryView.TimePeriod
    @ObservedObject var activityManager: ActivityManager
    
    var recentActivities: [ActivityEntry] {
        activityManager.getRecentActivities(days: period.days)
    }
    
    var topActivity: (ActivityType, Int)? {
        let grouped = Dictionary(grouping: recentActivities, by: { $0.type })
        return grouped.max(by: { $0.value.count < $1.value.count }).map { ($0.key, $0.value.count) }
    }
    
    var totalDuration: TimeInterval {
        recentActivities.reduce(0) { $0 + $1.duration }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Summary")
                .font(.headline)
            
            if !recentActivities.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        Text("Total Activities")
                        Spacer()
                        Text("\(recentActivities.count)")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Total Duration")
                        Spacer()
                        Text(formatDuration(totalDuration))
                            .fontWeight(.medium)
                    }
                    
                    if let (activity, count) = topActivity {
                        HStack {
                            Text("Most Frequent")
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: activity.icon)
                                    .font(.caption)
                                    .foregroundColor(activity.color)
                                Text("\(activity.rawValue) (\(count)x)")
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .font(.subheadline)
            } else {
                Text("No activities tracked in this period")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Insights Card
struct InsightsCard: View {
    let period: SummaryView.TimePeriod
    @ObservedObject var moodProfile: MoodProfile
    @ObservedObject var healthKit: HealthKitManager
    
    var insight: String {
        let recentMoods = moodProfile.getRecentMood(days: period.days)
        let avgMood = moodProfile.getAverageMood(days: period.days)
        
        if recentMoods.isEmpty {
            return "Start tracking your mood daily to see personalized insights!"
        }
        
        // Check for patterns
        let morningMoods = recentMoods.filter {
            Calendar.current.component(.hour, from: $0.timestamp) < 12
        }
        let eveningMoods = recentMoods.filter {
            Calendar.current.component(.hour, from: $0.timestamp) >= 18
        }
        
        if !morningMoods.isEmpty && !eveningMoods.isEmpty {
            let morningAvg = morningMoods.reduce(0) { $0 + $1.value } / Double(morningMoods.count)
            let eveningAvg = eveningMoods.reduce(0) { $0 + $1.value } / Double(eveningMoods.count)
            
            if morningAvg > eveningAvg + 1 {
                return "You tend to feel better in the mornings. Consider scheduling important tasks early."
            } else if eveningAvg > morningAvg + 1 {
                return "Your mood improves throughout the day. Save challenging tasks for later."
            }
        }
        
        if avgMood >= 7 {
            return "You're doing great! Your average mood is above 7. Keep up the positive habits!"
        } else if avgMood >= 5 {
            return "You're maintaining balance. Consider adding more activities that boost your mood."
        } else {
            return "This has been a challenging period. Remember to be kind to yourself and seek support."
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                Text("Insight")
                    .font(.headline)
            }
            
            Text(insight)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

// MARK: - Stat Card
struct SummaryStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    SummaryView(
        healthKit: HealthKitManager(),
        moodProfile: MoodProfile()
    )
}