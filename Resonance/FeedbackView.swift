import SwiftUI
import MessageUI

struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @State private var feedbackType = "Feature Request"
    @State private var feedbackText = ""
    @State private var email = ""
    @State private var showingMailView = false
    @State private var showingAlert = false
    
    let feedbackTypes = ["Bug Report", "Feature Request", "General Feedback", "Performance Issue"]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(colors: [.purple, .blue], 
                                             startPoint: .topLeading, 
                                             endPoint: .bottomTrailing)
                            )
                        
                        Text("Help Us Improve Resonance")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Your feedback shapes the future of this app")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)
                
                Section("Feedback Type") {
                    Picker("Type", selection: $feedbackType) {
                        ForEach(feedbackTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Your Feedback") {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 150)
                        .placeholder(when: feedbackText.isEmpty) {
                            Text("Tell us what's on your mind...")
                                .foregroundColor(.secondary)
                        }
                }
                
                Section("Contact (Optional)") {
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section {
                    Button(action: submitFeedback) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Feedback")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .listRowBackground(
                        LinearGradient(colors: [.blue, .purple], 
                                     startPoint: .leading, 
                                     endPoint: .trailing)
                    )
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Join our TestFlight", systemImage: "airplane")
                            .font(.headline)
                        Text("Get early access to new features and help test upcoming releases")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Link(destination: URL(string: "https://testflight.apple.com/join/YOURCODE")!) {
                            Text("Join Beta Program")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Thank You!", isPresented: $showingAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your feedback has been received. We truly appreciate you helping us make Resonance better!")
        }
    }
    
    private func submitFeedback() {
        // In production, this would send to your backend
        // For now, we'll compose an email or save locally
        
        let feedback = """
        Type: \(feedbackType)
        Email: \(email.isEmpty ? "Not provided" : email)
        
        Feedback:
        \(feedbackText)
        
        App Version: 1.0.0 (Beta)
        iOS Version: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        """
        
        print("Feedback submitted: \(feedback)")
        
        // For now, show success alert
        showingAlert = true
        
        // In production, send to your server:
        // sendToBackend(feedback)
    }
}

// Extension for placeholder in TextEditor
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .topLeading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
                    .padding(.top, 8)
                    .padding(.leading, 5)
            }
            self
        }
    }
}

#Preview {
    FeedbackView()
}