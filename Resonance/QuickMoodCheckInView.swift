import SwiftUI

struct QuickMoodCheckInView: View {
    @ObservedObject var moodProfile: MoodProfile
    @State private var currentMood: Double = 5.0
    @State private var selectedTag: MoodTag?
    @State private var isExpanded = false
    @State private var hasCheckedIn = false
    
    init(moodProfile: MoodProfile? = nil) {
        self._moodProfile = ObservedObject(wrappedValue: moodProfile ?? MoodProfile())
    }
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let successFeedback = UINotificationFeedbackGenerator()
    
    var moodEmoji: String {
        switch currentMood {
        case 0..<2: return "😔"
        case 2..<4: return "😕"
        case 4..<6: return "😐"
        case 6..<8: return "🙂"
        case 8...10: return "😊"
        default: return "😐"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if !hasCheckedIn {
                // Collapsed state - just the emoji slider
                VStack(spacing: 16) {
                    Text("How are you feeling?")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Large emoji display
                    Text(moodEmoji)
                        .font(.system(size: 60))
                        .scaleEffect(isExpanded ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: currentMood)
                    
                    // Mood slider with emoji endpoints
                    HStack {
                        Text("😔")
                            .font(.title2)
                        
                        Slider(value: $currentMood, in: 1...10, step: 1) { _ in
                            // On end of drag
                            if !isExpanded {
                                expandForTags()
                            }
                        }
                        .tint(Color(hue: 0.3 * (currentMood / 10.0), saturation: 0.5, brightness: 0.9))
                        .onChange(of: currentMood) { oldValue, newValue in
                            impactFeedback.impactOccurred()
                        }
                        
                        Text("😊")
                            .font(.title2)
                    }
                    .padding(.horizontal)
                    
                    // Context tags (appear after first interaction)
                    if isExpanded {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(MoodTag.allCases, id: \.self) { tag in
                                    TagButton(
                                        tag: tag,
                                        isSelected: selectedTag == tag,
                                        action: {
                                            selectTag(tag)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                )
                .padding()
                
            } else {
                // Success state
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                        .scaleEffect(hasCheckedIn ? 1.0 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: hasCheckedIn)
                    
                    Text("Mood tracked!")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Streak: \(moodProfile.streak.currentStreak) days 🔥")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                )
                .padding()
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
        .animation(.easeInOut(duration: 0.5), value: hasCheckedIn)
    }
    
    private func expandForTags() {
        withAnimation {
            isExpanded = true
        }
        
        // Auto-save after 3 seconds if no tag selected
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if !hasCheckedIn {
                saveMood()
            }
        }
    }
    
    private func selectTag(_ tag: MoodTag) {
        selectedTag = tag
        impactFeedback.impactOccurred()
        
        // Save immediately after tag selection
        saveMood()
    }
    
    private func saveMood() {
        let entry = MoodEntry(
            timestamp: Date(),
            value: currentMood,
            tag: selectedTag
        )
        
        moodProfile.addEntry(entry)
        successFeedback.notificationOccurred(.success)
        
        withAnimation {
            hasCheckedIn = true
        }
        
        // Reset after showing success
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                hasCheckedIn = false
                isExpanded = false
                currentMood = 5.0
                selectedTag = nil
            }
        }
    }
}

struct TagButton: View {
    let tag: MoodTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tag.icon)
                    .font(.system(size: 14))
                Text(tag.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? tag.color : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(tag.color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    QuickMoodCheckInView()
        .background(Color(.systemGroupedBackground))
}