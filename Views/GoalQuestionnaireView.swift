//
//  GoalQuestionnaireView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI

struct GoalQuestionnaireView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var flowEngine = GoalQuestionnaireFlowEngine()
    @ObservedObject var goalsViewModel: GoalsViewModel
    @ObservedObject var friendsViewModel: FriendsViewModel
    
    @State private var showingReview = false
    @State private var currentAnswer: Any? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                if let question = flowEngine.getCurrentQuestion() {
                    VStack(spacing: 0) {
                        // Progress indicator
                        ProgressBarView(
                            currentStep: flowEngine.questionHistory.count + 1,
                            totalSteps: estimateTotalSteps()
                        )
                        .padding()
                        
                        // Question content
                        ScrollView {
                            VStack(spacing: 24) {
                                QuestionContentView(
                                    question: question,
                                    answer: $currentAnswer,
                                    flowEngine: flowEngine,
                                    friendsViewModel: friendsViewModel
                                )
                            }
                            .padding()
                        }
                        
                        // Navigation buttons
                        HStack(spacing: 16) {
                            if flowEngine.canGoBack {
                                Button(action: {
                                    flowEngine.moveToPrevious()
                                    // Restore previous answer when going back
                                    restoreAnswerForCurrentQuestion()
                                }) {
                                    Text("Back")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(.systemGray5))
                                        .foregroundColor(.primary)
                                        .cornerRadius(10)
                                }
                            } else {
                                Spacer()
                                    .frame(maxWidth: .infinity)
                            }
                            
                            Button(action: {
                                handleAnswer()
                            }) {
                                Text(flowEngine.getNextQuestion() == nil ? "Review" : "Next")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(canProceed() ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(!canProceed())
                        }
                        .padding()
                    }
                } else {
                    // Review screen (when currentQuestionID is nil and we have history)
                    if !flowEngine.questionHistory.isEmpty {
                        GoalReviewView(
                            flowEngine: flowEngine,
                            goalsViewModel: goalsViewModel,
                            friendsViewModel: friendsViewModel,
                            onDismiss: { dismiss() }
                        )
                        .onAppear {
                            // When review appears, we need to ensure we can go back
                            // The review view will handle navigation back
                        }
                    } else {
                        // Loading state
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Create Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                flowEngine.start()
                if let userId = goalsViewModel.userId {
                    friendsViewModel.setUserId(userId)
                }
                // Restore answer for initial question if it exists
                restoreAnswerForCurrentQuestion()
            }
            .onChange(of: flowEngine.currentQuestionID) { newQuestionID in
                // When question changes, restore the answer if it exists
                if newQuestionID != nil {
                    restoreAnswerForCurrentQuestion()
                }
            }
        }
    }
    
    private func handleAnswer() {
        guard let question = flowEngine.getCurrentQuestion() else { return }
        
        // Save answer based on question type
        switch question.id {
        case .goalName:
            if let text = currentAnswer as? String {
                flowEngine.answers.goalName = text
            }
        case .goalType:
            if let optionId = currentAnswer as? String {
                flowEngine.answers.goalType = optionId
            }
        case .buddyOrSolo:
            if let buddyInfo = currentAnswer as? (UUID?, Bool) {
                flowEngine.answers.buddyId = buddyInfo.0
                flowEngine.answers.isSolo = buddyInfo.1
            }
        case .taskBeingTracked:
            if let text = currentAnswer as? String {
                flowEngine.answers.taskBeingTracked = text
            }
        case .insertListItems:
            if let items = currentAnswer as? [String] {
                flowEngine.answers.listItems = items
            }
        case .keepStreak:
            if let value = currentAnswer as? Bool {
                flowEngine.answers.keepStreak = value
            }
        case .trackDailyQuantity:
            if let value = currentAnswer as? Bool {
                flowEngine.answers.trackDailyQuantity = value
            }
        case .unitTracked:
            if let unit = currentAnswer as? String {
                flowEngine.answers.unitTracked = unit
            }
        case .challengeOrFriendly:
            if let optionId = currentAnswer as? String {
                flowEngine.answers.challengeOrFriendly = optionId
            }
        case .winningCondition:
            if let optionId = currentAnswer as? String {
                flowEngine.answers.winningCondition = optionId
                // Update winning condition question with dynamic options
                flowEngine.updateWinningConditionQuestion()
            }
        case .winningNumber:
            if let number = currentAnswer as? Int {
                flowEngine.answers.winningNumber = number
            }
        case .endDate:
            if let date = currentAnswer as? Date {
                flowEngine.answers.endDate = date
            }
        case .winnersPrize:
            if let text = currentAnswer as? String {
                flowEngine.answers.winnersPrize = text
            }
        }
        
        // Move to next question
        flowEngine.moveToNext()
        currentAnswer = nil
        
        // If we've reached the end, the review screen will show automatically
    }
    
    private func canProceed() -> Bool {
        guard let question = flowEngine.getCurrentQuestion() else { return false }
        
        switch question.type {
        case .textInput, .numberInput:
            if let text = currentAnswer as? String {
                return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if let number = currentAnswer as? Int {
                return number > 0
            }
            return false
        case .multipleChoice, .yesNo, .unitSelection:
            return currentAnswer != nil
        case .buddySelection:
            // Can proceed if solo is selected or buddy is selected
            if let buddyInfo = currentAnswer as? (UUID?, Bool) {
                return buddyInfo.0 != nil || buddyInfo.1 == true
            }
            return false
        case .listInput:
            if let items = currentAnswer as? [String] {
                return !items.isEmpty
            }
            return false
        case .dateInput:
            return currentAnswer is Date
        }
    }
    
    private func estimateTotalSteps() -> Int {
        // Estimate based on goal type and challenge mode
        var steps = 3 // name, type, buddy
        
        switch flowEngine.answers.goalType {
        case "list_tracker":
            steps += 2 // task, challenge/friendly
            if flowEngine.answers.isChallenge {
                steps += 3 // winning condition, number/date, prize
            }
        case "daily_tracker":
            steps += 3 // streak, quantity, unit (if quantity)
            if flowEngine.answers.trackDailyQuantity == false {
                steps -= 1 // no unit question
            }
            steps += 1 // challenge/friendly
            if flowEngine.answers.isChallenge {
                steps += 3 // winning condition, number/date, prize
            }
        case "list_created_by_user":
            steps += 2 // list items, challenge/friendly
            if flowEngine.answers.isChallenge {
                steps += 3 // winning condition, number/date, prize
            }
        default:
            break
        }
        
        return max(steps, 5) // Minimum estimate
    }
    
    /// Restore the answer for the current question from saved answers
    private func restoreAnswerForCurrentQuestion() {
        guard let question = flowEngine.getCurrentQuestion() else { return }
        
        switch question.id {
        case .goalName:
            currentAnswer = flowEngine.answers.goalName
        case .goalType:
            currentAnswer = flowEngine.answers.goalType
        case .buddyOrSolo:
            currentAnswer = (flowEngine.answers.buddyId, flowEngine.answers.isSolo ?? false)
        case .taskBeingTracked:
            currentAnswer = flowEngine.answers.taskBeingTracked
        case .insertListItems:
            currentAnswer = flowEngine.answers.listItems
        case .keepStreak:
            currentAnswer = flowEngine.answers.keepStreak
        case .trackDailyQuantity:
            // Only restore if there's a value, otherwise keep it nil
            if let value = flowEngine.answers.trackDailyQuantity {
                currentAnswer = value
            } else {
                currentAnswer = nil
            }
        case .unitTracked:
            currentAnswer = flowEngine.answers.unitTracked
        case .challengeOrFriendly:
            currentAnswer = flowEngine.answers.challengeOrFriendly
        case .winningCondition:
            currentAnswer = flowEngine.answers.winningCondition
        case .winningNumber:
            currentAnswer = flowEngine.answers.winningNumber
        case .endDate:
            currentAnswer = flowEngine.answers.endDate
        case .winnersPrize:
            currentAnswer = flowEngine.answers.winnersPrize
        }
    }
}

// MARK: - Progress Bar View

struct ProgressBarView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Question Content View

struct QuestionContentView: View {
    let question: Question
    @Binding var answer: Any?
    @ObservedObject var flowEngine: GoalQuestionnaireFlowEngine
    @ObservedObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Question title
            Text(question.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
            
            // Question description
            if let description = question.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            // Question input based on type
            switch question.type {
            case .textInput:
                TextInputQuestionView(
                    question: question,
                    answer: $answer
                )
                
            case .multipleChoice:
                MultipleChoiceQuestionView(
                    question: question,
                    answer: $answer,
                    flowEngine: flowEngine
                )
                
            case .buddySelection:
                BuddySelectionQuestionView(
                    question: question,
                    answer: $answer,
                    friendsViewModel: friendsViewModel
                )
                
            case .listInput:
                ListInputQuestionView(
                    question: question,
                    answer: $answer
                )
                
            case .yesNo:
                YesNoQuestionView(
                    question: question,
                    answer: $answer
                )
                
            case .unitSelection:
                UnitSelectionQuestionView(
                    question: question,
                    answer: $answer
                )
                
            case .dateInput:
                DateInputQuestionView(
                    question: question,
                    answer: $answer
                )
                
            case .numberInput:
                NumberInputQuestionView(
                    question: question,
                    answer: $answer
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

