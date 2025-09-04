import SwiftUI
import Charts
import CoreLocation

struct ActivityTrackingView: View {
    let activityType: ActivityType
    let customName: String?
    @ObservedObject var activityManager: ActivityManager
    @ObservedObject var healthKit: HealthKitManager
    @ObservedObject var moodProfile: MoodProfile
    @Environment(\.dismiss) var dismiss
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var currentHeartRate: Double = 0
    @State private var moodBefore: Double = 5.0
    @State private var moodAfter: Double = 5.0
    @State private var notesBefore: String = ""
    @State private var notesAfter: String = ""
    @State private var showingMoodBefore = true
    @State private var showingCompletion = false
    
    var displayName: String {
        if activityType == .other {
            return customName ?? "Activity"
        }
        return activityType.rawValue
    }
    
    func moodBasedNotePlaceholder(mood: Double, isBefore: Bool) -> String {
        if isBefore {
            switch mood {
            case 0..<3: return "Feeling down, hoping this helps..."
            case 3..<5: return "Not great, need a boost..."
            case 5..<7: return "Feeling okay, ready to improve..."
            case 7..<9: return "Feeling good, let's keep it up!"
            case 9...10: return "Feeling amazing! Let's go!"
            default: return "How are you feeling?"
            }
        } else {
            switch mood {
            case 0..<3: return "Still struggling, but I tried..."
            case 3..<5: return "A bit better, small progress..."
            case 5..<7: return "Definitely helped, feeling more balanced..."
            case 7..<9: return "Much better! This really helped!"
            case 9...10: return "Incredible! Feel so energized!"
            default: return "How was it?"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if showingMoodBefore && !activityManager.isTracking {
                    // Pre-activity mood check
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("How are you feeling?")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Before: \(displayName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            MoodSlider(mood: $moodBefore)
                                .onChange(of: moodBefore) { oldValue, newValue in
                                    // Update placeholder when mood changes
                                    if notesBefore.isEmpty {
                                        notesBefore = moodBasedNotePlaceholder(mood: newValue, isBefore: true)
                                    }
                                }
                            
                            // Notes field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Note (optional)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                TextField(
                                    moodBasedNotePlaceholder(mood: moodBefore, isBefore: true),
                                    text: $notesBefore,
                                    axis: .vertical
                                )
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(2...4)
                            }
                            
                            Button("Start \(displayName)") {
                                startTracking()
                            }
                            .buttonStyle(PrimaryActionButton(color: activityType.color))
                        }
                        .padding()
                    }
                    
                } else if activityManager.isTracking && !showingCompletion {
                    // Activity tracking with real-time data
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header with timer
                            VStack(spacing: 8) {
                                Text(displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(formatTime(elapsedTime))
                                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                            }
                            .padding(.top)
                            
                            // Metrics Grid
                            ActivityMetricsGrid(
                                activityType: activityType,
                                heartRate: activityManager.currentHeartRate,
                                distance: activityManager.currentDistance,
                                steps: activityManager.currentSteps,
                                pace: activityManager.currentPace,
                                calories: estimateCurrentCalories()
                            )
                            .padding(.horizontal)
                            
                            // Heart Rate Graph
                            if !activityManager.activityDataPoints.isEmpty {
                                HeartRateGraph(dataPoints: activityManager.activityDataPoints)
                                    .frame(height: 200)
                                    .padding(.horizontal)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .frame(height: 200)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "chart.line.uptrend.xyaxis")
                                                .font(.largeTitle)
                                                .foregroundColor(.gray)
                                            Text("Gathering data...")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    )
                                    .padding(.horizontal)
                            }
                            
                            // Control buttons
                            HStack(spacing: 20) {
                                Button("Cancel") {
                                    cancelActivity()
                                }
                                .buttonStyle(SecondaryActionButton())
                                
                                Button("Finish") {
                                    finishActivity()
                                }
                                .buttonStyle(PrimaryActionButton(color: .green))
                            }
                            .padding()
                        }
                    }
                    
                } else if showingCompletion {
                    // Post-activity mood check - matches pre-activity format
                    ScrollView {
                        VStack(spacing: 20) {
                            // Success indicator
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Nice work!")
                                        .font(.headline)
                                    Text("\(formatTime(elapsedTime)) of \(displayName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if activityManager.activityHeartRates.count > 0 {
                                    let avgHR = activityManager.activityHeartRates.reduce(0, +) / Double(activityManager.activityHeartRates.count)
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(Int(avgHR))")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                        Text("avg bpm")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            Text("How are you feeling?")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("After: \(displayName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            MoodSlider(mood: $moodAfter)
                                .onChange(of: moodAfter) { oldValue, newValue in
                                    // Update placeholder when mood changes
                                    if notesAfter.isEmpty {
                                        notesAfter = moodBasedNotePlaceholder(mood: newValue, isBefore: false)
                                    }
                                }
                            
                            // Mood comparison
                            if abs(moodAfter - moodBefore) > 0.5 {
                                HStack {
                                    Image(systemName: moodAfter > moodBefore ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                        .foregroundColor(moodAfter > moodBefore ? .green : .orange)
                                    
                                    Text(moodAfter > moodBefore ? 
                                         "Mood improved by \(String(format: "%.0f", abs(moodAfter - moodBefore))) points!" :
                                         "Mood changed by \(String(format: "%.0f", abs(moodAfter - moodBefore))) points")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                            }
                            
                            // Notes field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Note (optional)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                TextField(
                                    moodBasedNotePlaceholder(mood: moodAfter, isBefore: false),
                                    text: $notesAfter,
                                    axis: .vertical
                                )
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(2...4)
                            }
                            
                            Button("Save & Close") {
                                completeActivity()
                            }
                            .buttonStyle(PrimaryActionButton(color: .blue))
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !activityManager.isTracking && !showingCompletion {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTracking() {
        showingMoodBefore = false
        
        // Get initial steps and distance
        let initialSteps = healthKit.todaysSteps
        let initialDistance = 0.0 // We'll track this from start
        
        activityManager.startActivity(
            type: activityType, 
            customName: customName, 
            moodBefore: moodBefore,
            initialSteps: initialSteps,
            initialDistance: initialDistance
        )
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
            
            // Update metrics every 2 seconds
            if Int(elapsedTime) % 2 == 0 {
                updateActivityMetrics()
            }
        }
        
        // Start monitoring heart rate and pedometer
        healthKit.startRealtimeHeartRateMonitoring()
        if shouldTrackDistance() {
            startLocationTracking()
        }
    }
    
    private func shouldTrackDistance() -> Bool {
        switch activityType {
        case .walk, .exercise, .workout, .dance:
            return true
        default:
            return false
        }
    }
    
    private func startLocationTracking() {
        // This would connect to CoreLocation for distance tracking
        // For now, we'll simulate with pedometer data
    }
    
    private func updateActivityMetrics() {
        // Fetch current heart rate
        let currentHR = healthKit.currentHeartRate
        
        // Fetch current steps
        let currentSteps = healthKit.todaysSteps
        
        // Simulate distance based on steps (average stride length)
        let strideLength = 0.762 // meters (average)
        let distance = Double(currentSteps - activityManager.startSteps) * strideLength
        
        // Update activity manager
        activityManager.updateActivityData(
            heartRate: currentHR > 0 ? currentHR : nil,
            steps: currentSteps,
            distance: shouldTrackDistance() ? distance : nil
        )
    }
    
    private func estimateCurrentCalories() -> Double {
        let minutes = elapsedTime / 60
        let baseRate: Double = {
            switch activityType {
            case .walk: return 4.0
            case .exercise, .workout: return 8.0
            case .dance: return 6.0
            case .stretch: return 2.5
            default: return 2.0
            }
        }()
        
        var multiplier = 1.0
        if activityManager.currentHeartRate > 140 { multiplier = 1.5 }
        else if activityManager.currentHeartRate > 120 { multiplier = 1.3 }
        else if activityManager.currentHeartRate > 100 { multiplier = 1.1 }
        
        return baseRate * minutes * multiplier
    }
    
    private func fetchCurrentHeartRate() {
        // This will get the latest heart rate from HealthKit
        currentHeartRate = healthKit.currentHeartRate
        if currentHeartRate > 0 {
            activityManager.addHeartRate(currentHeartRate)
        }
    }
    
    private func finishActivity() {
        // Stop the timer but don't dismiss yet
        timer?.invalidate()
        showingCompletion = true
    }
    
    private func cancelActivity() {
        timer?.invalidate()
        activityManager.cancelActivity()
        dismiss()
    }
    
    private func completeActivity() {
        // Combine notes from before and after
        var combinedNotes = ""
        if !notesBefore.isEmpty && notesBefore != moodBasedNotePlaceholder(mood: moodBefore, isBefore: true) {
            combinedNotes = "Before: \(notesBefore)"
        }
        if !notesAfter.isEmpty && notesAfter != moodBasedNotePlaceholder(mood: moodAfter, isBefore: false) {
            if !combinedNotes.isEmpty { combinedNotes += "\n" }
            combinedNotes += "After: \(notesAfter)"
        }
        
        activityManager.stopActivity(moodAfter: moodAfter, notes: combinedNotes.isEmpty ? nil : combinedNotes)
        
        // Also log mood entry if mood changed significantly
        if abs(moodAfter - moodBefore) > 1 {
            let moodEntry = MoodEntry(
                timestamp: Date(),
                value: moodAfter,
                tag: activityToMoodTag(activityType),
                note: "After \(displayName): \(combinedNotes.isEmpty ? "Mood improved" : combinedNotes)"
            )
            moodProfile.addEntry(moodEntry)
        }
        
        dismiss()
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func activityToMoodTag(_ activity: ActivityType) -> MoodTag {
        switch activity {
        case .exercise, .workout, .walk, .stretch, .dance:
            return .health
        case .callFriend:
            return .relationship
        case .breathe, .meditate:
            return .sleep
        default:
            return .general
        }
    }
}

struct MoodSlider: View {
    @Binding var mood: Double
    
    var moodEmoji: String {
        switch mood {
        case 0..<2: return "😔"
        case 2..<4: return "😕"
        case 4..<6: return "😐"
        case 6..<8: return "🙂"
        case 8...10: return "😊"
        default: return "😐"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text(moodEmoji)
                .font(.system(size: 60))
            
            HStack {
                Text("😔")
                    .font(.title2)
                
                Slider(value: $mood, in: 1...10, step: 1)
                    .tint(Color(hue: 0.3 * (mood / 10.0), saturation: 0.5, brightness: 0.9))
                
                Text("😊")
                    .font(.title2)
            }
            
            Text(String(format: "%.0f/10", mood))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct PrimaryActionButton: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryActionButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// Custom Activity Input Sheet
struct CustomActivitySheet: View {
    @Binding var customName: String
    @Binding var isPresented: Bool
    let onStart: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("What activity are you doing?")
                    .font(.headline)
                
                TextField("e.g., CrossFit, Running, Yoga", text: $customName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Start Activity") {
                    if !customName.isEmpty {
                        onStart(customName)
                        isPresented = false
                    }
                }
                .buttonStyle(PrimaryActionButton(color: .blue))
                .disabled(customName.isEmpty)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Custom Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Activity Metrics Grid
struct ActivityMetricsGrid: View {
    let activityType: ActivityType
    let heartRate: Double
    let distance: Double
    let steps: Int
    let pace: Double
    let calories: Double
    
    var metricsToShow: [(String, String, String, Color)] {
        var metrics: [(String, String, String, Color)] = []
        
        // Always show heart rate
        if heartRate > 0 {
            metrics.append(("\(Int(heartRate))", "bpm", "heart.fill", .red))
        }
        
        // Activity-specific metrics
        switch activityType {
        case .walk, .exercise, .workout:
            if distance > 0 {
                let km = distance / 1000
                metrics.append((String(format: "%.2f", km), "km", "location.fill", .blue))
            }
            if steps > 0 {
                metrics.append(("\(steps)", "steps", "figure.walk", .green))
            }
            if pace > 0 {
                let minPart = Int(pace)
                let secPart = Int((pace - Double(minPart)) * 60)
                metrics.append((String(format: "%d:%02d", minPart, secPart), "min/km", "speedometer", .orange))
            }
        case .dance:
            if steps > 0 {
                metrics.append(("\(steps)", "moves", "music.note", .purple))
            }
        default:
            break
        }
        
        // Always show calories
        if calories > 0 {
            metrics.append((String(format: "%.0f", calories), "cal", "flame.fill", .orange))
        }
        
        return metrics
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(metricsToShow, id: \.0) { metric in
                MetricCard(value: metric.0, unit: metric.1, icon: metric.2, color: metric.3)
            }
        }
    }
}

struct MetricCard: View {
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Heart Rate Graph
struct HeartRateGraph: View {
    let dataPoints: [ActivityDataPoint]
    
    var minHR: Double {
        dataPoints.compactMap { $0.heartRate }.min() ?? 60
    }
    
    var maxHR: Double {
        dataPoints.compactMap { $0.heartRate }.max() ?? 180
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Heart Rate")
                .font(.headline)
            
            Chart {
                ForEach(dataPoints) { point in
                    if let hr = point.heartRate {
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("HR", hr)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red.opacity(0.8), Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value("HR", hr)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red.opacity(0.2), Color.orange.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
            }
            .frame(height: 180)
            .chartYScale(domain: (minHR - 10)...(maxHR + 10))
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

#Preview {
    ActivityTrackingView(
        activityType: .walk,
        customName: nil,
        activityManager: ActivityManager(),
        healthKit: HealthKitManager(),
        moodProfile: MoodProfile()
    )
}