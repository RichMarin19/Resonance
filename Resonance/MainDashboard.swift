import SwiftUI

struct MainDashboard: View {
    let learningStyle: LearningStyle
    @ObservedObject var moodProfile: MoodProfile
    @EnvironmentObject var healthKit: HealthKitManager
    @StateObject private var activityManager = ActivityManager()
    @State private var showingFullMoodEntry = false
    @State private var isRefreshing = false
    @State private var showingActivityTracker = false
    @State private var selectedActivity: ActivityType?
    @State private var showingCustomActivitySheet = false
    @State private var customActivityName = ""
    @State private var showingInsights = false
    @State private var showingFeedback = false
    @State private var showingBetaWelcome = false
    
    init(learningStyle: LearningStyle, moodProfile: MoodProfile? = nil) {
        self.learningStyle = learningStyle
        self._moodProfile = ObservedObject(wrappedValue: moodProfile ?? MoodProfile())
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    WelcomeHeader(moodProfile: moodProfile)
                        .padding(.horizontal)
                    
                    // Quick Mood Check-In Card with shared MoodProfile
                    QuickMoodCheckInView(moodProfile: moodProfile)
                        .padding(.vertical)
                    
                    // Today's Summary with See All button
                    TodaySummaryCard(healthKit: healthKit, moodProfile: moodProfile, showingSummaryView: $showingInsights)
                        .padding(.horizontal)
                    
                    // Quick Actions - Now functional!
                    QuickActionsGrid(
                        learningStyle: learningStyle,
                        onActionTapped: { activity in
                            if activity == .other {
                                showingCustomActivitySheet = true
                            } else {
                                selectedActivity = activity
                                showingActivityTracker = true
                            }
                        }
                    )
                    .padding(.horizontal)
                    
                    // Recent Activity
                    RecentActivityCard(moodProfile: moodProfile)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Resonance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
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
                        
                        Button(action: { showingFeedback = true }) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshAllData) {
                        Image(systemName: isRefreshing ? "arrow.clockwise.circle.fill" : "arrow.clockwise.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                }
            }
        }
        .sheet(isPresented: $showingActivityTracker) {
            if let activity = selectedActivity {
                ActivityTrackingView(
                    activityType: activity,
                    customName: activity == .other ? customActivityName : nil,
                    activityManager: activityManager,
                    healthKit: healthKit,
                    moodProfile: moodProfile
                )
            }
        }
        .sheet(isPresented: $showingCustomActivitySheet) {
            CustomActivitySheet(
                customName: $customActivityName,
                isPresented: $showingCustomActivitySheet
            ) { name in
                customActivityName = name
                selectedActivity = .other
                showingActivityTracker = true
            }
        }
        .sheet(isPresented: $showingInsights) {
            SummaryView(
                healthKit: healthKit,
                moodProfile: moodProfile
            )
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackView()
        }
        .sheet(isPresented: $showingBetaWelcome) {
            BetaWelcomeView(isPresented: $showingBetaWelcome)
        }
        .onAppear {
            refreshAllData()
            // Show beta welcome on first launch
            if !UserDefaults.standard.bool(forKey: "HasSeenBetaWelcome") {
                showingBetaWelcome = true
                UserDefaults.standard.set(true, forKey: "HasSeenBetaWelcome")
            }
        }
    }
    
    private func refreshAllData() {
        isRefreshing = true
        
        // Fetch last month of health data
        healthKit.fetchAllHealthData()
        healthKit.fetchHistoricalData(days: 30)
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Stop animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isRefreshing = false
        }
    }
}

struct WelcomeHeader: View {
    @ObservedObject var moodProfile: MoodProfile
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title2)
                .fontWeight(.bold)
            
            if moodProfile.streak.currentStreak > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(moodProfile.streak.currentStreak) day streak!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Start your wellness journey today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TodaySummaryCard: View {
    @ObservedObject var healthKit: HealthKitManager
    @ObservedObject var moodProfile: MoodProfile
    @Binding var showingSummaryView: Bool
    
    var todaysMood: Double? {
        let todaysEntries = moodProfile.entries.filter {
            Calendar.current.isDateInToday($0.timestamp)
        }
        guard !todaysEntries.isEmpty else { return nil }
        return todaysEntries.map { $0.value }.reduce(0, +) / Double(todaysEntries.count)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with gradient background
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Summary")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(Date().formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { showingSummaryView = true }) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(colors: [.blue, .blue.opacity(0.8)], 
                                     startPoint: .leading, 
                                     endPoint: .trailing)
                    )
                    .cornerRadius(15)
                }
            }
            
            // Primary Metrics Row - Stress & Energy (larger display)
            HStack(spacing: 16) {
                PrimaryMetricCard(
                    title: "Stress Level",
                    value: Int(healthKit.stressLevel),
                    maxValue: 100,
                    icon: "brain.head.profile",
                    gradient: stressGradient(for: healthKit.stressLevel),
                    status: stressStatus(for: healthKit.stressLevel)
                )
                
                PrimaryMetricCard(
                    title: "Energy Level",
                    value: Int(healthKit.energyLevel),
                    maxValue: 100,
                    icon: "battery.100.bolt",
                    gradient: energyGradient(for: healthKit.energyLevel),
                    status: energyStatus(for: healthKit.energyLevel)
                )
            }
            
            // Secondary Metrics Grid (3x3 for other 7 metrics)
            VStack(spacing: 12) {
                // Row 1
                HStack(spacing: 12) {
                    CompactMetricCard(
                        icon: "face.smiling",
                        value: todaysMood != nil ? String(format: "%.1f", todaysMood!) : "--",
                        label: "Mood",
                        color: todaysMood != nil ? Color.init(hue: 0.3 * (todaysMood! / 10.0), saturation: 0.5, brightness: 0.9) : .gray
                    )
                    CompactMetricCard(
                        icon: "moon.fill",
                        value: String(format: "%.1f", healthKit.sleepHours),
                        label: "Sleep (h)",
                        color: .purple
                    )
                    CompactMetricCard(
                        icon: "figure.walk",
                        value: formatSteps(healthKit.todaysSteps),
                        label: "Steps",
                        color: .green
                    )
                }
                
                // Row 2
                HStack(spacing: 12) {
                    CompactMetricCard(
                        icon: "heart.fill",
                        value: healthKit.currentHeartRate > 0 ? "\(Int(healthKit.currentHeartRate))" : "--",
                        label: "HR",
                        color: .red
                    )
                    CompactMetricCard(
                        icon: "waveform.path.ecg",
                        value: healthKit.latestHRV > 0 ? "\(Int(healthKit.latestHRV))" : "--",
                        label: "HRV",
                        color: .orange
                    )
                    CompactMetricCard(
                        icon: "heart.text.square",
                        value: healthKit.restingHeartRate > 0 ? "\(Int(healthKit.restingHeartRate))" : "--",
                        label: "RHR",
                        color: .pink
                    )
                }
                
                // Row 3
                HStack(spacing: 12) {
                    CompactMetricCard(
                        icon: "wind",
                        value: healthKit.respiratoryRate > 0 ? "\(Int(healthKit.respiratoryRate))" : "--",
                        label: "Resp",
                        color: .cyan
                    )
                    CompactMetricCard(
                        icon: "flame.fill",
                        value: "\(healthKit.activeCalories)",
                        label: "Calories",
                        color: .orange
                    )
                    CompactMetricCard(
                        icon: "figure.run",
                        value: "\(healthKit.workoutMinutes)",
                        label: "Active Min",
                        color: .green
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        )
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 10000 {
            return String(format: "%.1fk", Double(steps) / 1000)
        } else if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000)
        } else {
            return "\(steps)"
        }
    }
    
    private func stressGradient(for value: Double) -> LinearGradient {
        if value < 30 {
            return LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if value < 60 {
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private func energyGradient(for value: Double) -> LinearGradient {
        if value >= 70 {
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if value >= 40 {
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private func stressStatus(for value: Double) -> String {
        if value < 30 { return "Low" }
        else if value < 60 { return "Moderate" }
        else { return "High" }
    }
    
    private func energyStatus(for value: Double) -> String {
        if value >= 70 { return "Great" }
        else if value >= 40 { return "Good" }
        else { return "Low" }
    }
}

// Primary metric cards for Stress and Energy
struct PrimaryMetricCard: View {
    let title: String
    let value: Int
    let maxValue: Int
    let icon: String
    let gradient: LinearGradient
    let status: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(gradient)
                Spacer()
                Text(status)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(gradient)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(value)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("/\(maxValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 6)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(gradient)
                        .frame(width: geometry.size.width * CGFloat(value) / CGFloat(maxValue), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

// Compact metric cards for secondary metrics
struct CompactMetricCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .lineLimit(1)
            
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.6))
        )
    }
}

struct QuickActionsGrid: View {
    let learningStyle: LearningStyle
    let onActionTapped: (ActivityType) -> Void
    
    var actions: [(ActivityType, String, String, Color)] {
        var baseActions: [(ActivityType, String, String, Color)] = []
        
        switch learningStyle {
        case .visual:
            baseActions = [
                (.breathe, "Breathe", "wind", .mint),
                (.journal, "Journal", "book.fill", .blue),
                (.meditate, "Meditate", "brain.head.profile", .purple),
                (.exercise, "Exercise", "figure.run", .orange)
            ]
        case .auditory:
            baseActions = [
                (.music, "Music", "music.note", .pink),
                (.podcast, "Podcast", "mic.fill", .blue),
                (.callFriend, "Call Friend", "phone.fill", .green),
                (.voiceNote, "Voice Note", "waveform", .orange)
            ]
        case .kinesthetic:
            baseActions = [
                (.walk, "Walk", "figure.walk", .green),
                (.stretch, "Stretch", "figure.flexibility", .blue),
                (.dance, "Dance", "music.note.house", .purple),
                (.workout, "Workout", "dumbbell.fill", .orange)
            ]
        }
        
        // Add "Other" option to all
        baseActions.append((.other, "Other", "plus.circle.fill", .gray))
        
        return baseActions
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(actions, id: \.1) { action in
                    QuickActionButton(
                        title: action.1,
                        icon: action.2,
                        color: action.3,
                        action: {
                            onActionTapped(action.0)
                        }
                    )
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 28)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
            
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

struct RecentActivityCard: View {
    @ObservedObject var moodProfile: MoodProfile
    @State private var showingProgress = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
                Button(action: { showingProgress = true }) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if moodProfile.entries.isEmpty {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundColor(.gray)
                    Text("Track your first mood to see activity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                // Mini mood trend for last 7 days
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { dayOffset in
                        MiniDayBar(
                            value: getDayMood(daysAgo: 6 - dayOffset),
                            day: getDayLabel(daysAgo: 6 - dayOffset)
                        )
                    }
                }
                .frame(height: 60)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
        .sheet(isPresented: $showingProgress) {
            NavigationView {
                ProgressDashboardView(moodProfile: moodProfile)
                    .navigationTitle("Activity Progress")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingProgress = false
                            }
                        }
                    }
            }
        }
    }
    
    private func getDayMood(daysAgo: Int) -> Double? {
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        let dayStart = calendar.startOfDay(for: targetDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        let dayEntries = moodProfile.entries.filter {
            $0.timestamp >= dayStart && $0.timestamp < dayEnd
        }
        
        guard !dayEntries.isEmpty else { return nil }
        return dayEntries.map { $0.value }.reduce(0, +) / Double(dayEntries.count)
    }
    
    private func getDayLabel(daysAgo: Int) -> String {
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: targetDate).prefix(1))
    }
}

struct MiniDayBar: View {
    let value: Double?
    let day: String
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    value != nil 
                    ? Color.init(hue: 0.3 * (value! / 10.0), saturation: 0.5, brightness: 0.9)
                    : Color(.systemGray5)
                )
                .frame(height: value != nil ? CGFloat(value! * 4) : 2)
                .frame(maxHeight: .infinity, alignment: .bottom)
            
            Text(day)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    MainDashboard(learningStyle: .visual, moodProfile: MoodProfile())
        .environmentObject(HealthKitManager())
}