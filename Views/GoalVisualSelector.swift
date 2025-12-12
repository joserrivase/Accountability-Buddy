//
//  GoalVisualSelector.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI

// MARK: - Visual Type Enum

enum VisualType {
    case list
    case userCreatedList
    case sumBox
    case sumBoxGoal
    case endDateBox
    case calendarWithCheck
    case streakCounter
    case totalDaysCount
    case barChart
    case barTotals
}

// MARK: - Visual Selector

struct GoalVisualSelector {
    static func getVisuals(for goal: Goal) -> [VisualType] {
        guard let goalType = goal.goalType else {
            // Fallback to old tracking method if no goal type
            return getLegacyVisuals(for: goal)
        }
        
        let isChallenge = goal.challengeOrFriendly == "challenge"
        let winningCondition = goal.winningCondition ?? ""
        
        switch goalType {
        case "list_tracker":
            // Always include list for list_tracker goals
            var visuals: [VisualType] = [.list]
            
            if isChallenge {
                // Check winning condition (case-insensitive)
                let lowercased = winningCondition.lowercased()
                if lowercased.contains("first to reach") || lowercased.contains("first_to_reach_x") {
                    // Visual 2: List Tracker + Challenge + First to reach X
                    // Only show sumBoxGoal (not sumBox)
                    visuals.append(.sumBoxGoal)
                } else if lowercased.contains("most_by_end_date") || 
                          (lowercased.contains("most") && (lowercased.contains("end date") || lowercased.contains("end_date"))) {
                    // Visual 3: List Tracker + Challenge + Most by end date
                    // Show sumBox and endDateBox
                    visuals.append(.sumBox)
                    visuals.append(.endDateBox)
                } else {
                    // Other challenge conditions - show sumBox
                    visuals.append(.sumBox)
                }
            } else {
                // Friendly goals - show sumBox
                visuals.append(.sumBox)
            }
            
            return visuals
            
        case "list_created_by_user":
            if !isChallenge {
                // Visual 4: List Created + Friendly
                return [.userCreatedList, .sumBoxGoal]
            } else {
                // Check winning condition (case-insensitive)
                let lowercased = winningCondition.lowercased()
                if lowercased.contains("first to finish") || lowercased.contains("first_to_finish") {
                    // Visual 5: List Created + Challenge + First to finish
                    return [.userCreatedList, .sumBoxGoal]
                } else if lowercased.contains("most_by_end_date") || 
                          (lowercased.contains("most") && (lowercased.contains("end date") || lowercased.contains("end_date"))) {
                    // Visual 6: List Created + Challenge + Most by end date
                    return [.userCreatedList, .sumBoxGoal, .endDateBox]
                } else {
                    return [.userCreatedList, .sumBoxGoal]
                }
            }
            
        case "daily_tracker":
            var visuals: [VisualType] = [.calendarWithCheck, .totalDaysCount]
            
            // Add streak counter if keep_streak is true
            if goal.keepStreak == true {
                visuals.append(.streakCounter)
            }
            
            // Add bar chart and totals if track_daily_quantity is true
            if goal.trackDailyQuantity == true {
                visuals.append(.barChart)
                visuals.append(.barTotals)
            }
            
            // Add sum box goal if winning condition is "first person to complete X number of units"
            if isChallenge && winningCondition.contains("first person to complete X number") {
                visuals.append(.sumBoxGoal)
            }
            
            return visuals
            
        default:
            return getLegacyVisuals(for: goal)
        }
    }
    
    private static func getLegacyVisuals(for goal: Goal) -> [VisualType] {
        // Fallback for goals created before questionnaire
        switch goal.trackingMethod {
        case .inputList:
            return [.list, .sumBox]
        case .trackDaysCompleted:
            return [.calendarWithCheck, .totalDaysCount]
        case .inputNumbers:
            return [.sumBox]
        }
    }
}

