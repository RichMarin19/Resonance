import SwiftUI

struct CrisisSupportView: View {
    @State private var showingBreathingExercise = false
    @State private var showingGroundingExercise = false
    @State private var pulseAnimation = false
    
    let crisisResources = [
        CrisisResource(
            title: "Call 988",
            action: .call(number: "988"),
            icon: "phone.circle.fill",
            color: .red
        ),
        CrisisResource(
            title: "Text HOME to 741741",
            action: .text(number: "741741", message: "HOME"),
            icon: "message.circle.fill",
            color: .blue
        ),
        CrisisResource(
            title: "Breathing Exercise",
            action: .breathe,
            icon: "wind",
            color: .mint
        ),
        CrisisResource(
            title: "Grounding Exercise",
            action: .exercise(type: .fiveFourThreeTwoOne),
            icon: "leaf.circle.fill",
            color: .green
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Emergency header
            VStack(spacing: 16) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                    .onAppear { pulseAnimation = true }
                
                Text("You're Not Alone")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Immediate help is available 24/7")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 30)
            
            // Crisis resources grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(crisisResources, id: \.title) { resource in
                    CrisisResourceButton(resource: resource) {
                        handleResourceAction(resource.action)
                    }
                }
            }
            .padding()
            
            // Safety reminder
            VStack(spacing: 12) {
                Text("If you're in immediate danger")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Button(action: { callEmergency() }) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Call 911")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 20)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingBreathingExercise) {
            BreathingExerciseView()
        }
        .sheet(isPresented: $showingGroundingExercise) {
            GroundingExerciseView()
        }
    }
    
    private func handleResourceAction(_ action: CrisisResource.CrisisAction) {
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
        
        switch action {
        case .call(let number):
            if let url = URL(string: "tel:\(number)") {
                UIApplication.shared.open(url)
            }
        case .text(let number, let message):
            if let url = URL(string: "sms:\(number)&body=\(message)") {
                UIApplication.shared.open(url)
            }
        case .breathe:
            showingBreathingExercise = true
        case .exercise(let type):
            switch type {
            case .fiveFourThreeTwoOne:
                showingGroundingExercise = true
            default:
                break
            }
        }
    }
    
    private func callEmergency() {
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.warning)
        
        if let url = URL(string: "tel:911") {
            UIApplication.shared.open(url)
        }
    }
}

struct CrisisResourceButton: View {
    let resource: CrisisResource
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(resource.color.opacity(0.15))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: resource.icon)
                        .font(.system(size: 32))
                        .foregroundColor(resource.color)
                }
                
                Text(resource.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct BreathingExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var breathPhase = "Inhale"
    @State private var circleScale: CGFloat = 0.5
    @State private var isBreathing = false
    @State private var currentCycle = 0
    
    let breathingCycle = [
        ("Inhale", 4.0, 1.0),
        ("Hold", 4.0, 1.0),
        ("Exhale", 4.0, 0.5),
        ("Hold", 4.0, 0.5)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Text("Box Breathing")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Follow the circle and text to regulate your breathing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 2)
                        .frame(width: 250, height: 250)
                    
                    // Breathing circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.mint.opacity(0.3), Color.blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 250, height: 250)
                        .scaleEffect(circleScale)
                        .animation(.easeInOut(duration: 4), value: circleScale)
                    
                    // Breathing text
                    VStack(spacing: 8) {
                        Text(breathPhase)
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        if isBreathing {
                            Text("Cycle \(currentCycle)/5")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Button(action: toggleBreathing) {
                    Text(isBreathing ? "Stop" : "Start")
                        .font(.headline)
                        .frame(width: 200)
                        .padding()
                        .background(isBreathing ? Color.red : Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func toggleBreathing() {
        isBreathing.toggle()
        if isBreathing {
            startBreathingCycle()
        } else {
            circleScale = 0.5
            breathPhase = "Inhale"
            currentCycle = 0
        }
    }
    
    private func startBreathingCycle() {
        currentCycle = 1
        runBreathingPhase(index: 0)
    }
    
    private func runBreathingPhase(index: Int) {
        guard isBreathing else { return }
        
        let phase = breathingCycle[index]
        breathPhase = phase.0
        circleScale = phase.2
        
        DispatchQueue.main.asyncAfter(deadline: .now() + phase.1) {
            let nextIndex = (index + 1) % breathingCycle.count
            
            if nextIndex == 0 {
                currentCycle += 1
                if currentCycle > 5 {
                    toggleBreathing()
                    return
                }
            }
            
            runBreathingPhase(index: nextIndex)
        }
    }
}

struct GroundingExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var userInputs: [String] = []
    @State private var currentInput = ""
    
    let steps = [
        ("5 things you can see", "eye", 5),
        ("4 things you can touch", "hand.raised", 4),
        ("3 things you can hear", "ear", 3),
        ("2 things you can smell", "nose", 2),
        ("1 thing you can taste", "mouth", 1)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if currentStep < steps.count {
                    // Current step
                    VStack(spacing: 20) {
                        Image(systemName: steps[currentStep].1)
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Name \(steps[currentStep].0)")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("This helps ground you in the present moment")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // Input field
                        TextField("Type here or just think about it", text: $currentInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .onSubmit {
                                if !currentInput.isEmpty {
                                    userInputs.append(currentInput)
                                    currentInput = ""
                                }
                            }
                        
                        // Progress
                        Text("\(userInputs.count)/\(steps[currentStep].2)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        // List of inputs
                        if !userInputs.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(userInputs, id: \.self) { input in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text(input)
                                            .font(.subheadline)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        Button(action: nextStep) {
                            Text(userInputs.count >= steps[currentStep].2 ? "Next" : "Skip")
                                .frame(width: 200)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(25)
                        }
                    }
                } else {
                    // Completion screen
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("Great job!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("You've successfully completed the grounding exercise")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { dismiss() }) {
                            Text("Done")
                                .frame(width: 200)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(25)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func nextStep() {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        
        currentStep += 1
        userInputs = []
        currentInput = ""
    }
}

#Preview {
    CrisisSupportView()
}