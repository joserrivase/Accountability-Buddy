//
//  GoalQuestionnaireFlowEngine.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import Foundation
import SwiftUI

/// Flow engine that manages the questionnaire flow based on user answers
/// This is the decision tree logic - modify this file to update the flow
@MainActor
class GoalQuestionnaireFlowEngine: ObservableObject {
    @Published var currentQuestionID: QuestionID?
    @Published var questionHistory: [QuestionID] = []
    @Published var answers = GoalQuestionnaireAnswers()
    
    // MARK: - Question Definitions
    // All questions are defined here for easy modification
    
    private let allQuestions: [QuestionID: Question] = [
        .goalName: Question(
            id: .goalName,
            type: .textInput,
            title: "What's the name of your goal?",
            description: "Give your goal a memorable name",
            placeholder: "e.g., Read More Books",
            validation: ValidationRule(isRequired: true, minLength: 1, maxLength: 100)
        ),
        
        .goalType: Question(
            id: .goalType,
            type: .multipleChoice,
            title: "What type of goal is this?",
            description: "Choose the tracking method that best fits your goal",
            options: [
                QuestionOption(
                    id: "list_tracker",
                    title: "List Tracker",
                    description: "Keep track of a list of \"tasks\" each user completed"
                ),
                QuestionOption(
                    id: "daily_tracker",
                    title: "Daily Tracker",
                    description: "Keep track of the daily progress each user completed"
                ),
                QuestionOption(
                    id: "list_created_by_user",
                    title: "List Created By User",
                    description: "Complete a list that the user created"
                )
            ]
        ),
        
        .buddyOrSolo: Question(
            id: .buddyOrSolo,
            type: .buddySelection,
            title: "Choose Buddy or go solo",
            description: "Add a buddy from your friends or select to do a solo goal"
        ),
        
        .taskBeingTracked: Question(
            id: .taskBeingTracked,
            type: .textInput,
            title: "What task are you tracking?",
            description: "What task are you completing?",
            placeholder: "e.g., Books Read, Projects Completed, Chores done, Courses completed",
            validation: ValidationRule(isRequired: true, minLength: 1, maxLength: 100)
        ),
        
        .insertListItems: Question(
            id: .insertListItems,
            type: .listInput,
            title: "Insert list of items to complete",
            description: "Create a list of items you want to complete"
        ),
        
        .keepStreak: Question(
            id: .keepStreak,
            type: .yesNo,
            title: "Do you want to keep a streak?",
            description: "Do you plan on doing this task every day? If so then consider keeping a daily streak going."
        ),
        
        .trackDailyQuantity: Question(
            id: .trackDailyQuantity,
            type: .yesNo,
            title: "Do you want to track a daily quantity?",
            description: "e.g., daily miles ran, daily pages read, daily minutes exercised"
        ),
        
        .unitTracked: Question(
            id: .unitTracked,
            type: .unitSelection,
            title: "What unit is being tracked?",
            description: "Select the unit for your daily quantity tracking"
        ),
        
        .challengeOrFriendly: Question(
            id: .challengeOrFriendly,
            type: .multipleChoice,
            title: "Challenge or Friendly?",
            description: "Do you want to have an ending winning condition to make this more competitive or keep it friendly?",
            options: [
                QuestionOption(
                    id: "friendly",
                    title: "Friendly",
                    description: "Keep it friendly - no competition"
                ),
                QuestionOption(
                    id: "challenge",
                    title: "Challenge",
                    description: "Add a winning condition to make it competitive"
                )
            ]
        ),
        
        .winningCondition: Question(
            id: .winningCondition,
            type: .multipleChoice,
            title: "What's the winning condition?",
            description: "How will the winner be determined?"
        ),
        
        .winningNumber: Question(
            id: .winningNumber,
            type: .numberInput,
            title: "What's the target number?",
            description: "Enter the number to reach",
            placeholder: "Enter number",
            validation: ValidationRule(isRequired: true)
        ),
        
        .endDate: Question(
            id: .endDate,
            type: .dateInput,
            title: "When does the challenge end?",
            description: "Select the end date for your challenge"
        ),
        
        .winnersPrize: Question(
            id: .winnersPrize,
            type: .textInput,
            title: "What is the winner's prize?",
            description: "Put something on the line to keep you more motivated",
            placeholder: "e.g., Winner buys dinner, Winner gets bragging rights",
            validation: ValidationRule(isRequired: true, minLength: 1, maxLength: 200)
        )
    ]
    
    // MARK: - Flow Logic
    
    /// Get the current question
    func getCurrentQuestion() -> Question? {
        guard let questionID = currentQuestionID else { return nil }
        return allQuestions[questionID]
    }
    
    /// Start the questionnaire
    func start() {
        questionHistory = []
        answers = GoalQuestionnaireAnswers()
        currentQuestionID = .goalName
    }
    
    /// Get the next question based on current answers
    func getNextQuestion() -> QuestionID? {
        guard let currentID = currentQuestionID else {
            return .goalName
        }
        
        // Decision tree logic
        switch currentID {
        case .goalName:
            return .goalType
            
        case .goalType:
            // All goal types go to buddy selection
            return .buddyOrSolo
            
        case .buddyOrSolo:
            // Branch based on goal type
            switch answers.goalType {
            case "list_tracker":
                return .taskBeingTracked
            case "daily_tracker":
                return .keepStreak
            case "list_created_by_user":
                return .insertListItems
            default:
                return nil
            }
            
        case .taskBeingTracked:
            // List tracker always goes to challenge/friendly
            return .challengeOrFriendly
            
        case .insertListItems:
            // List created by user goes to challenge/friendly
            return .challengeOrFriendly
            
        case .keepStreak:
            // Daily tracker: after streak question, ask about quantity
            return .trackDailyQuantity
            
        case .trackDailyQuantity:
            // If tracking quantity, ask for unit, otherwise go to challenge/friendly
            if answers.trackDailyQuantity == true {
                return .unitTracked
            } else {
                return .challengeOrFriendly
            }
            
        case .unitTracked:
            // After unit selection, go to challenge/friendly
            return .challengeOrFriendly
            
        case .challengeOrFriendly:
            // If challenge, ask for winning condition, otherwise done
            if answers.isChallenge {
                return .winningCondition
            } else {
                return nil // End of flow for friendly
            }
            
        case .winningCondition:
            // Determine what to ask next based on winning condition and context
            return getNextAfterWinningCondition()
            
        case .winningNumber:
            // After number, ask for prize
            return .winnersPrize
            
        case .endDate:
            // After end date, ask for prize
            return .winnersPrize
            
        case .winnersPrize:
            // Final question
            return nil
        }
    }
    
    /// Determine next question after winning condition is selected
    private func getNextAfterWinningCondition() -> QuestionID? {
        guard let winningCondition = answers.winningCondition else { return nil }
        
        // Check if winning condition requires a number or date
        if winningCondition.contains("X number") || winningCondition.contains("X number of") || winningCondition.contains("reach") {
            return .winningNumber
        } else if winningCondition.contains("end date") || winningCondition.contains("by") {
            return .endDate
        }
        
        // If no number/date needed, go to prize
        return .winnersPrize
    }
    
    /// Move to next question
    func moveToNext() {
        if let nextID = getNextQuestion() {
            if let currentID = currentQuestionID {
                questionHistory.append(currentID)
            }
            currentQuestionID = nextID
        } else {
            // Reached end of flow - add current question to history before going to review
            if let currentID = currentQuestionID {
                questionHistory.append(currentID)
            }
            currentQuestionID = nil
        }
    }
    
    /// Move to previous question
    func moveToPrevious() {
        guard !questionHistory.isEmpty else { return }
        
        if let previousID = questionHistory.last {
            currentQuestionID = previousID
            questionHistory.removeLast()
        }
    }
    
    /// Check if we can go back
    var canGoBack: Bool {
        return !questionHistory.isEmpty
    }
    
    /// Check if we're at the end
    var isComplete: Bool {
        return currentQuestionID == nil && !questionHistory.isEmpty
    }
    
    /// Check if we're on review screen
    var isOnReview: Bool {
        return currentQuestionID == nil && !questionHistory.isEmpty
    }
    
    /// Get dynamic winning condition options based on context
    func getWinningConditionOptions() -> [QuestionOption] {
        var options: [QuestionOption] = []
        
        switch answers.goalType {
        case "list_tracker":
            if let task = answers.taskBeingTracked {
                options.append(QuestionOption(
                    id: "first_to_reach_x",
                    title: "First to reach X number of \(task)",
                    description: "First person to complete a target number wins"
                ))
                options.append(QuestionOption(
                    id: "most_by_end_date",
                    title: "Most number of \(task) by an end date",
                    description: "Whoever has the most by the end date wins"
                ))
            }
            
        case "list_created_by_user":
            options.append(QuestionOption(
                id: "first_to_finish",
                title: "First to finish the list",
                description: "First person to complete all items wins"
            ))
            options.append(QuestionOption(
                id: "most_by_end_date",
                title: "Most number of finished items by end date",
                description: "Whoever has completed the most items by the end date wins"
            ))
            
        case "daily_tracker":
            options.append(QuestionOption(
                id: "most_days_by_end_date",
                title: "Most days completed by end date",
                description: "Whoever has the most completed days wins"
            ))
            
            if answers.keepStreak == true {
                options.append(QuestionOption(
                    id: "longest_streak_by_end_date",
                    title: "Longest streak by end date",
                    description: "Whoever has the longest continuous streak wins"
                ))
                options.append(QuestionOption(
                    id: "first_to_reach_x_days_streak",
                    title: "First to reach X number of days streak",
                    description: "First person to reach a target streak length wins"
                ))
            }
            
            if answers.trackDailyQuantity == true, let unit = answers.unitTracked {
                options.append(QuestionOption(
                    id: "most_amount_by_end_date",
                    title: "Most amount of \(unit) completed by end date",
                    description: "Whoever has accumulated the most \(unit) wins"
                ))
                options.append(QuestionOption(
                    id: "first_to_complete_x_amount",
                    title: "First person to complete X number of \(unit)",
                    description: "First person to reach a target amount wins"
                ))
            }
            
        default:
            break
        }
        
        return options
    }
    
    /// Update winning condition question with dynamic options
    func updateWinningConditionQuestion() {
        // This will be called when we reach the winning condition question
        // The view will use getWinningConditionOptions() to display options
    }
}

