//
//  GoalQuestionnaire.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import Foundation

// MARK: - Question Types

enum QuestionType: String, Codable {
    case textInput = "text_input"
    case multipleChoice = "multiple_choice"
    case buddySelection = "buddy_selection"
    case listInput = "list_input"
    case yesNo = "yes_no"
    case unitSelection = "unit_selection"
    case dateInput = "date_input"
    case numberInput = "number_input"
}

// MARK: - Question IDs

enum QuestionID: String, Codable {
    case goalName = "goal_name"
    case goalType = "goal_type"
    case buddyOrSolo = "buddy_or_solo"
    case taskBeingTracked = "task_being_tracked"
    case challengeOrFriendly = "challenge_or_friendly"
    case winningCondition = "winning_condition"
    case winnersPrize = "winners_prize"
    case insertListItems = "insert_list_items"
    case keepStreak = "keep_streak"
    case trackDailyQuantity = "track_daily_quantity"
    case unitTracked = "unit_tracked"
    case winningNumber = "winning_number"
    case endDate = "end_date"
}

// MARK: - Question Model

struct Question: Identifiable {
    let id: QuestionID
    let type: QuestionType
    let title: String
    let description: String?
    let options: [QuestionOption]?
    let placeholder: String?
    let validation: ValidationRule?
    
    init(id: QuestionID, type: QuestionType, title: String, description: String? = nil, options: [QuestionOption]? = nil, placeholder: String? = nil, validation: ValidationRule? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.options = options
        self.placeholder = placeholder
        self.validation = validation
    }
}

// MARK: - Question Option

struct QuestionOption: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String?
    
    init(id: String, title: String, description: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
    }
}

// MARK: - Validation Rule

struct ValidationRule {
    let isRequired: Bool
    let minLength: Int?
    let maxLength: Int?
    let pattern: String?
    
    init(isRequired: Bool = true, minLength: Int? = nil, maxLength: Int? = nil, pattern: String? = nil) {
        self.isRequired = isRequired
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
    }
}

// MARK: - Answer Storage

struct GoalQuestionnaireAnswers {
    // Core answers
    var goalName: String?
    var goalType: String? // "list_tracker", "daily_tracker", "list_created_by_user"
    var buddyId: UUID?
    var isSolo: Bool?
    var taskBeingTracked: String?
    var challengeOrFriendly: String? // "challenge", "friendly"
    var winningCondition: String?
    var winnersPrize: String?
    var listItems: [String]?
    var keepStreak: Bool?
    var trackDailyQuantity: Bool?
    var unitTracked: String?
    var winningNumber: Int?
    var endDate: Date?
    
    // Helper to get tracking method for Goal creation
    func getTrackingMethod() -> TrackingMethod? {
        guard let goalType = goalType else { return nil }
        
        switch goalType {
        case "list_tracker":
            return .inputList
        case "daily_tracker":
            // Daily tracker maps to trackDaysCompleted
            return .trackDaysCompleted
        case "list_created_by_user":
            return .inputList
        default:
            return nil
        }
    }
    
    // Helper to check if challenge mode
    var isChallenge: Bool {
        return challengeOrFriendly == "challenge"
    }
}

// MARK: - Unit Options

enum TrackingUnit: String, CaseIterable {
    case miles = "Mi"
    case kilometers = "Km"
    case minutes = "Min"
    case hours = "Hr"
    case pages = "Pages"
    case other = "Other"
    
    var displayName: String {
        return self.rawValue
    }
}

