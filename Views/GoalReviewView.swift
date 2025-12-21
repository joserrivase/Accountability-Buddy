//
//  GoalReviewView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI

struct GoalReviewView: View {
    @ObservedObject var flowEngine: GoalQuestionnaireFlowEngine
    @ObservedObject var goalsViewModel: GoalsViewModel
    @ObservedObject var friendsViewModel: FriendsViewModel
    let onDismiss: () -> Void
    
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Goal Summary
                    VStack(alignment: .leading, spacing: 16) {
                            ReviewSection(title: "Goal Name") {
                            Text(flowEngine.answers.goalName ?? "Not set")
                                .font(.body)
                        }
                        
                        ReviewSection(title: "Goal Type") {
                            Text(getGoalTypeDisplayName())
                                .font(.body)
                        }
                        
                        ReviewSection(title: "Accountability") {
                            if flowEngine.answers.isSolo == true {
                                Text("Solo Goal")
                                    .font(.body)
                            } else if let buddyId = flowEngine.answers.buddyId,
                                      let buddy = friendsViewModel.friends.first(where: { $0.userId == buddyId }) {
                                HStack {
                                    if let imageUrlString = buddy.profileImageUrl,
                                       let imageUrl = URL(string: imageUrlString) {
                                        RemoteImageView(url: imageUrl) {
                                            Circle()
                                                .fill(Color(.systemGray5))
                                                .overlay(ProgressView())
                                        }
                                        .scaledToFill()
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text(buddy.displayName != "User" ? buddy.displayName : (buddy.username ?? "Buddy"))
                                        .font(.body)
                                }
                            } else {
                                Text("Not set")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Goal-specific details
                        if let task = flowEngine.answers.taskBeingTracked {
                            ReviewSection(title: "Task Being Tracked") {
                                Text(task)
                                    .font(.body)
                            }
                        }
                        
                        if let items = flowEngine.answers.listItems, !items.isEmpty {
                            ReviewSection(title: "List Items") {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                                        Text("\(index + 1). \(item)")
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        
                        if flowEngine.answers.goalType == "daily_tracker" {
                            if let keepStreak = flowEngine.answers.keepStreak {
                                ReviewSection(title: "Keep Streak") {
                                    Text(keepStreak ? "Yes" : "No")
                                        .font(.body)
                                }
                            }
                            
                            if let trackQuantity = flowEngine.answers.trackDailyQuantity {
                                ReviewSection(title: "Track Daily Quantity") {
                                    Text(trackQuantity ? "Yes" : "No")
                                        .font(.body)
                                }
                                
                                if trackQuantity, let unit = flowEngine.answers.unitTracked {
                                    ReviewSection(title: "Unit Tracked") {
                                        Text(unit)
                                            .font(.body)
                                    }
                                }
                            }
                        }
                        
                        ReviewSection(title: "Mode") {
                            Text(flowEngine.answers.isChallenge ? "Challenge" : "Friendly")
                                .font(.body)
                        }
                        
                        // Challenge details
                        if flowEngine.answers.isChallenge {
                            if let objective = formattedChallengeObjective() {
                                ReviewSection(title: "Challenge Objective") {
                                    Text(objective)
                                        .font(.body)
                                }
                            }
                            
                            if let winningNumber = flowEngine.answers.winningNumber {
                                ReviewSection(title: "Target Number") {
                                    Text("\(winningNumber)")
                                        .font(.body)
                                }
                            }
                            
                            if let endDate = flowEngine.answers.endDate {
                                ReviewSection(title: "End Date") {
                                    Text(endDate, style: .date)
                                        .font(.body)
                                }
                            }
                            
                            if let prize = flowEngine.answers.winnersPrize {
                                ReviewSection(title: "Challenge Stakes") {
                                    Text(prize)
                                        .font(.body)
                                }
                            }
                        }
                    }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Navigation buttons at bottom
                HStack(spacing: 16) {
                    Button(action: {
                        // Go back to the last question
                        if !flowEngine.questionHistory.isEmpty {
                            flowEngine.moveToPrevious()
                        }
                    }) {
                        Text("Back")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        Task {
                            await createGoal()
                        }
                    }) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isCreating ? "Creating..." : "Create Goal")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isCreating || !canCreateGoal() ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isCreating || !canCreateGoal())
                }
                .padding(.horizontal)
                .padding(.bottom)
                }
                .padding(.vertical)
            }
            .navigationTitle("Review Goal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func getGoalTypeDisplayName() -> String {
        switch flowEngine.answers.goalType {
        case "list_tracker":
            return "List Tracker"
        case "daily_tracker":
            return "Daily Tracker"
        case "list_created_by_user":
            return "List Created By User"
        default:
            return "Not set"
        }
    }
    
    private func canCreateGoal() -> Bool {
        guard let goalName = flowEngine.answers.goalName,
              !goalName.isEmpty,
              let trackingMethod = flowEngine.answers.getTrackingMethod() else {
            return false
        }
        
        // Additional validation based on goal type
        switch flowEngine.answers.goalType {
        case "list_tracker":
            return flowEngine.answers.taskBeingTracked != nil
        case "list_created_by_user":
            return flowEngine.answers.listItems != nil && !flowEngine.answers.listItems!.isEmpty
        case "daily_tracker":
            return true // Daily tracker doesn't require additional fields
        default:
            return false
        }
    }
    
    private func createGoal() async {
        guard let goalName = flowEngine.answers.goalName,
              let trackingMethod = flowEngine.answers.getTrackingMethod() else {
            errorMessage = "Missing required information"
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        // Determine buddy ID
        let buddyId: UUID? = flowEngine.answers.isSolo == true ? nil : flowEngine.answers.buddyId
        
        // Check if this is the user's first goal (before creating)
        let isFirstGoal = goalsViewModel.goals.isEmpty
        
        // Create the goal with all questionnaire answers
        await goalsViewModel.createGoal(
            name: goalName,
            trackingMethod: trackingMethod,
            buddyId: buddyId,
            questionnaireAnswers: flowEngine.answers
        )
        
        if goalsViewModel.errorMessage == nil {
            // Request notification permission after first goal creation
            if isFirstGoal {
                await requestNotificationPermission()
            }
            onDismiss()
        } else {
            errorMessage = goalsViewModel.errorMessage
        }
        
        isCreating = false
    }
    
    private func requestNotificationPermission() async {
        let status = await NotificationService.shared.checkAuthorizationStatus()
        
        // Only request if not already determined
        if status == .notDetermined {
            // Request permission - iOS will show the system permission dialog
            // The user will see: "Accountability Buddy" Would Like to Send You Notifications
            // with options: Don't Allow / Allow
            let granted = await NotificationService.shared.requestAuthorization()
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("⚠️ Notification permission denied")
            }
        } else if status == .denied {
            print("⚠️ Notification permission was previously denied")
        }
    }
}

// MARK: - Helpers
private extension GoalReviewView {
    func formattedChallengeObjective() -> String? {
        guard let raw = flowEngine.answers.winningCondition else { return nil }
        let lc = raw.lowercased()
        let unit = flowEngine.answers.unitTracked ?? "units"
        let number = flowEngine.answers.winningNumber
        let endDateString: String? = {
            if let date = flowEngine.answers.endDate {
                let df = DateFormatter()
                df.dateStyle = .medium
                df.timeStyle = .none
                return df.string(from: date)
            }
            return nil
        }()
        
        if lc.contains("first to reach") || lc.contains("first_to_reach_x") {
            if let number = number {
                return "First to reach \(number) \(unit)"
            }
            return "First to reach the target"
        } else if lc.contains("first to complete") || lc.contains("first_to_complete_x_amount") {
            if let number = number {
                return "First to complete \(number) \(unit)"
            }
            return "First to complete the required amount"
        } else if lc.contains("first to finish") || lc.contains("first_to_finish") {
            return "First to finish the list"
        } else if lc.contains("most_by_end_date") ||
                    (lc.contains("most") && (lc.contains("end date") || lc.contains("end_date"))) {
            if let endDateString = endDateString {
                return "Most completed by \(endDateString)"
            }
            return "Most completed by the deadline"
        }
        
        let prettified = raw
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prettified.isEmpty else { return nil }
        return prettified.prefix(1).capitalized + prettified.dropFirst()
    }
}

// MARK: - Review Section Component

struct ReviewSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            content
        }
    }
}

