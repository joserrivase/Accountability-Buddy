//
//  GoalsViewModel.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import Foundation
import SwiftUI

@MainActor
class GoalsViewModel: ObservableObject {
    @Published var goals: [GoalWithProgress] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    var userId: UUID? // Made public for questionnaire access
    
    func setUserId(_ userId: UUID) {
        self.userId = userId
        Task {
            await loadGoals()
        }
    }
    
    func loadGoals() async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedGoals = try await supabaseService.fetchGoals(userId: userId)
            
            // Fetch progress for ALL goals in parallel (not sequential)
            var goalsWithProgress: [GoalWithProgress] = []
            
            await withTaskGroup(of: (Goal, GoalProgress?, GoalProgress?).self) { group in
                // Add all tasks to the group
                for goal in fetchedGoals {
                    group.addTask {
                        // Fetch progress for this goal
                        let progressList = try? await self.supabaseService.fetchGoalProgress(goalId: goal.id)
                        
                        let creatorProgress = progressList?.first { $0.userId == goal.creatorId }
                        let buddyProgress = goal.buddyId != nil ? progressList?.first { $0.userId == goal.buddyId } : nil
                        
                        return (goal, creatorProgress, buddyProgress)
                    }
                }
                
                // Collect results as they complete
                for await (goal, creatorProgress, buddyProgress) in group {
                    goalsWithProgress.append(GoalWithProgress(
                        goal: goal,
                        creatorProgress: creatorProgress,
                        buddyProgress: buddyProgress
                    ))
                }
            }
            
            // Sort by updated_at to maintain order
            goalsWithProgress.sort { $0.goal.updatedAt > $1.goal.updatedAt }
            
            goals = goalsWithProgress
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createGoal(name: String, trackingMethod: TrackingMethod, buddyId: UUID?, questionnaireAnswers: GoalQuestionnaireAnswers) async {
        guard let userId = userId else {
            errorMessage = "User ID not available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await supabaseService.createGoal(
                name: name,
                trackingMethod: trackingMethod,
                creatorId: userId,
                buddyId: buddyId,
                goalType: questionnaireAnswers.goalType,
                taskBeingTracked: questionnaireAnswers.taskBeingTracked,
                listItems: questionnaireAnswers.listItems,
                keepStreak: questionnaireAnswers.keepStreak,
                trackDailyQuantity: questionnaireAnswers.trackDailyQuantity,
                unitTracked: questionnaireAnswers.unitTracked,
                challengeOrFriendly: questionnaireAnswers.challengeOrFriendly,
                winningCondition: questionnaireAnswers.winningCondition,
                winningNumber: questionnaireAnswers.winningNumber,
                endDate: questionnaireAnswers.endDate,
                winnersPrize: questionnaireAnswers.winnersPrize
            )
            await loadGoals()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteGoal(goalId: UUID) async {
        errorMessage = nil
        
        do {
            try await supabaseService.deleteGoal(goalId: goalId)
            await loadGoals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateGoalProgress(goalId: UUID, numericValue: Double? = nil, completedDays: [String]? = nil, listItems: [GoalListItem]? = nil) async {
        guard let userId = userId else {
            errorMessage = "User ID not available"
            return
        }
        
        errorMessage = nil
        
        do {
            _ = try await supabaseService.updateGoalProgress(
                goalId: goalId,
                userId: userId,
                numericValue: numericValue,
                completedDays: completedDays,
                listItems: listItems
            )
            await loadGoals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

