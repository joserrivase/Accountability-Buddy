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
            
            // Fetch progress for each goal
            var goalsWithProgress: [GoalWithProgress] = []
            
            for goal in fetchedGoals {
                let progressList = try await supabaseService.fetchGoalProgress(goalId: goal.id)
                
                let creatorProgress = progressList.first { $0.userId == goal.creatorId }
                let buddyProgress = goal.buddyId != nil ? progressList.first { $0.userId == goal.buddyId } : nil
                
                goalsWithProgress.append(GoalWithProgress(
                    goal: goal,
                    creatorProgress: creatorProgress,
                    buddyProgress: buddyProgress
                ))
            }
            
            goals = goalsWithProgress
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createGoal(name: String, trackingMethod: TrackingMethod, buddyId: UUID?) async {
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
                buddyId: buddyId
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

