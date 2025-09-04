import SwiftUI

struct DailyWisdomView: View {
    @StateObject private var wisdomManager = DailyWisdomManager()
    @State private var currentWisdom: DailyWisdom?
    @State private var isFavorite = false
    @State private var showingShare = false
    @State private var animateCard = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Daily Wisdom")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(Date(), style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: refreshWisdom) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if let wisdom = currentWisdom {
                // Wisdom Card
                VStack(spacing: 20) {
                    // Category badge
                    HStack {
                        Text(wisdom.category.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(categoryColor(wisdom.category).opacity(0.2))
                            .foregroundColor(categoryColor(wisdom.category))
                            .cornerRadius(20)
                        
                        Spacer()
                        
                        Button(action: toggleFavorite) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(isFavorite ? .red : .gray)
                                .font(.title3)
                        }
                    }
                    
                    // Wisdom content
                    Text(wisdom.content)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let source = wisdom.source {
                        Text("— \(source)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: { showingShare = true }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        Button(action: applyWisdom) {
                            Label("Apply This", systemImage: "lightbulb.fill")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    categoryColor(wisdom.category).opacity(0.05),
                                    categoryColor(wisdom.category).opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(categoryColor(wisdom.category).opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)
                .scaleEffect(animateCard ? 1.0 : 0.95)
                .opacity(animateCard ? 1.0 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateCard)
                
                // Related exercises
                RelatedExercisesSection(category: wisdom.category)
                
            } else {
                // Loading state
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxHeight: .infinity)
            }
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadDailyWisdom()
        }
        .sheet(isPresented: $showingShare) {
            if let wisdom = currentWisdom {
                ShareSheet(items: [wisdom.content])
            }
        }
    }
    
    private func categoryColor(_ category: DailyWisdom.WisdomCategory) -> Color {
        switch category {
        case .cbt: return .blue
        case .dbt: return .purple
        case .mindfulness: return .green
        case .motivation: return .orange
        case .grounding: return .brown
        }
    }
    
    private func loadDailyWisdom() {
        currentWisdom = wisdomManager.getTodaysWisdom()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animateCard = true
        }
        
        let haptic = UIImpactFeedbackGenerator(style: .soft)
        haptic.impactOccurred()
    }
    
    private func refreshWisdom() {
        animateCard = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentWisdom = wisdomManager.getRandomWisdom()
            animateCard = true
        }
        
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }
    
    private func toggleFavorite() {
        isFavorite.toggle()
        
        if isFavorite {
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)
            
            // Save to favorites
            if let wisdom = currentWisdom {
                wisdomManager.saveFavorite(wisdom)
            }
        }
    }
    
    private func applyWisdom() {
        // Navigate to related exercise or journaling
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
    }
}

struct RelatedExercisesSection: View {
    let category: DailyWisdom.WisdomCategory
    
    var exercises: [(String, String)] {
        switch category {
        case .cbt:
            return [
                ("Thought Log", "doc.text"),
                ("Cognitive Restructuring", "brain")
            ]
        case .dbt:
            return [
                ("TIPP Technique", "thermometer"),
                ("Radical Acceptance", "checkmark.circle")
            ]
        case .mindfulness:
            return [
                ("Body Scan", "figure.stand"),
                ("Mindful Breathing", "wind")
            ]
        case .motivation:
            return [
                ("Goal Setting", "target"),
                ("Gratitude List", "heart.text.square")
            ]
        case .grounding:
            return [
                ("5-4-3-2-1", "hand.raised"),
                ("Progressive Relaxation", "person.fill.checkmark")
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Try These Exercises")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(exercises, id: \.0) { exercise in
                        ExerciseCard(title: exercise.0, icon: exercise.1)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ExerciseCard: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

// Wisdom Manager
class DailyWisdomManager: ObservableObject {
    private let wisdomDatabase = [
        DailyWisdom(content: "Your thoughts are not facts. They're just mental events that come and go.", category: .cbt, source: "CBT Principle"),
        DailyWisdom(content: "What you resist, persists. Practice accepting this moment exactly as it is.", category: .mindfulness, source: "Mindfulness Teaching"),
        DailyWisdom(content: "You can't control the waves, but you can learn to surf.", category: .dbt, source: "Jon Kabat-Zinn"),
        DailyWisdom(content: "Small steps daily lead to big changes yearly. Focus on progress, not perfection.", category: .motivation, source: nil),
        DailyWisdom(content: "Ground yourself: Notice 5 things you see, 4 you can touch, 3 you hear, 2 you smell, 1 you taste.", category: .grounding, source: "5-4-3-2-1 Technique"),
        DailyWisdom(content: "Between stimulus and response, there is a space. In that space is our power to choose.", category: .cbt, source: "Viktor Frankl"),
        DailyWisdom(content: "Radical acceptance means accepting life on life's terms, not resisting what you cannot change.", category: .dbt, source: "DBT Skill"),
        DailyWisdom(content: "Breathe in calm, breathe out tension. Your breath is always with you as an anchor.", category: .mindfulness, source: nil),
        DailyWisdom(content: "You are allowed to be both a masterpiece and a work in progress simultaneously.", category: .motivation, source: nil),
        DailyWisdom(content: "When overwhelmed, return to your body. Feel your feet on the ground, your breath in your chest.", category: .grounding, source: "Somatic Practice")
    ]
    
    func getTodaysWisdom() -> DailyWisdom {
        // Use date to consistently show same wisdom for the day
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = dayOfYear % wisdomDatabase.count
        return wisdomDatabase[index]
    }
    
    func getRandomWisdom() -> DailyWisdom {
        wisdomDatabase.randomElement() ?? wisdomDatabase[0]
    }
    
    func saveFavorite(_ wisdom: DailyWisdom) {
        // Save to UserDefaults or Core Data
        var favorites = getFavorites()
        favorites.append(wisdom)
        
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: "favoriteWisdoms")
        }
    }
    
    func getFavorites() -> [DailyWisdom] {
        if let data = UserDefaults.standard.data(forKey: "favoriteWisdoms"),
           let decoded = try? JSONDecoder().decode([DailyWisdom].self, from: data) {
            return decoded
        }
        return []
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DailyWisdomView()
}