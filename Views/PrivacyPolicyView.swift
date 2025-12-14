import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Last Updated: December 11, 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Group {
                        Text("1. Information We Collect")
                            .font(.headline)
                        Text("""
                        • Account info (name, username, email).
                        • Goal data you create (goal details, progress, buddy info).
                        • Usage data (app interactions, device identifiers, crash reports).
                        • Optional profile photo.
                        """)
                        
                        Text("2. How We Use Information")
                            .font(.headline)
                        Text("""
                        • Provide and improve core features (goals, progress, reminders).
                        • Sync data across your devices.
                        • Send essential notifications (goal updates, buddy requests). You can control notifications in iOS Settings.
                        • Security, fraud prevention, and support.
                        """)
                        
                        Text("3. Sharing")
                            .font(.headline)
                        Text("""
                        • We do not sell your data.
                        • Shared only with: (a) service providers (e.g., hosting, analytics) under contract, (b) when you collaborate with a buddy (relevant goal data is shared with them), (c) if required by law or to protect rights and safety.
                        """)
                        
                        Text("4. Data Retention")
                            .font(.headline)
                        Text("""
                        • Kept as long as your account is active.
                        • You can delete your account in Settings > Delete Account; this deletes your personal data from our active systems, subject to limited legal/backup requirements.
                        """)
                        
                        Text("5. Your Choices")
                            .font(.headline)
                        Text("""
                        • Manage notifications in iOS Settings.
                        • Update or delete your data via the app (profile, goals, progress).
                        • Delete your account anytime in Settings.
                        """)
                        
                        Text("6. Security")
                            .font(.headline)
                        Text("""
                        • We use encryption in transit (HTTPS) and industry-standard safeguards.
                        • No method is 100% secure; protect your device and credentials.
                        """)
                        
                        Text("7. Children")
                            .font(.headline)
                        Text("""
                        • Not directed to children under 13 (or under the minimum age in your region).
                        • If we learn we collected data from a child, we will delete it.
                        """)
                        
                        Text("8. International Users")
                            .font(.headline)
                        Text("""
                        • Data may be processed in the United States or other countries.
                        • We apply appropriate safeguards where required.
                        """)
                        
                        Text("9. Changes to this Policy")
                            .font(.headline)
                        Text("""
                        • We may update this policy; material changes will be announced in-app.
                        """)
                        
                        Text("10. Contact")
                            .font(.headline)
                        Text("""
                        • Email: jose.r.rivas.e@gmail.com
                        """)
                    }
                    .font(.body)
                    .foregroundColor(.primary)
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        // Dismiss via environment
                        dismiss()
                    }
                }
            }
        }
    }
    
    @Environment(\.dismiss) private var dismiss
}

