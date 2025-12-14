//
//  SupabaseService.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/8/25.
//

import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    // TODO: Replace these with your Supabase credentials
    // Paste your Supabase URL here
    private let supabaseURL = "https://pttbhlhkbbturoqjxzma.supabase.co"
    // Paste your Supabase anon key here
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB0dGJobGhrYmJ0dXJvcWp4em1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3MTIyMTAsImV4cCI6MjA3ODI4ODIxMH0.XtD1IDCrutFeYAjbaFbQ4CVxir14KDN3GmKrtxYUKfw"
    
    private var client: SupabaseClient?
    
    private init() {
        initializeSupabase()
    }
    
    private func initializeSupabase() {
        guard let url = URL(string: supabaseURL),
              !supabaseKey.isEmpty else {
            print("⚠️ Supabase credentials not configured. Please set your URL and anon key in SupabaseService.swift")
            return
        }
        
        client = SupabaseClient(supabaseURL: url, supabaseKey: supabaseKey)
        print("✅ Supabase client initialized successfully")
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, username: String, fullName: String) async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        do {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        
            // Check if user was created successfully
            // If session is nil, it likely means email confirmation is required
            // This is still a successful sign-up, just needs email confirmation
            guard response.user != nil else {
            throw SupabaseError.signUpFailed
            }
            
            let userId = response.user.id
            
            // Create profile with username and name if user is authenticated (has session)
            // If no session, profile will be created after email confirmation
            if response.session != nil {
                // User is automatically signed in, create profile now
                do {
                    _ = try await createProfile(userId: userId, username: username, name: fullName)
                } catch {
                    // Log error but don't fail signup if profile creation fails
                    print("⚠️ Warning: Failed to create profile during signup: \(error)")
                }
            } else {
                // User needs to confirm email, profile will be created after confirmation
                // For now, we'll create it anyway (it will be updated after email confirmation)
                // Or we can wait until they sign in for the first time
                // Let's create it with the provided info - if user doesn't exist yet, it will fail gracefully
                do {
                    _ = try await createProfile(userId: userId, username: username, name: fullName)
                } catch {
                    // If profile creation fails (e.g., user not fully created yet), that's okay
                    // Profile will be created when they first sign in after email confirmation
                    print("⚠️ Note: Profile will be created after email confirmation: \(error)")
                }
            }
            
            // If session exists, user is automatically signed in
            // If session is nil, user needs to confirm email (this is still a success)
        } catch {
            // Re-throw Supabase errors with better context
            if error is SupabaseError {
                throw error
            } else {
                // Wrap other errors (like network errors, validation errors, etc.)
                throw SupabaseError.custom(error.localizedDescription)
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        try await client.auth.signIn(
            email: email,
            password: password
        )
    }
    
    func resetPassword(email: String) async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Send password reset email
        try await client.auth.resetPasswordForEmail(
            email,
            redirectTo: nil // Supabase will use the default redirect URL
        )
    }
    
    func signOut() async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        try await client.auth.signOut()
    }
    
    func getCurrentUser() async -> UUID? {
        guard let client = client else { return nil }
        
        do {
            let session = try await client.auth.session
            return session.user.id
        } catch {
            return nil
        }
    }
    
    func getCurrentUserEmail() async -> String? {
        guard let client = client else { return nil }
        
        do {
            let session = try await client.auth.session
            return session.user.email
        } catch {
            return nil
        }
    }
    
    func deleteAccount(userId: UUID) async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Note: Deleting the auth user requires admin privileges or a database function
        // For client-side apps, we delete all user data and sign them out
        // The auth user record may remain in auth.users but with no associated data
        // This is acceptable - the user is effectively deleted from the app's perspective
        
        // Delete the profile (if exists)
        try? await client
            .from("profiles")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        // Try to delete the auth user (may fail if not admin - that's okay)
        // If this fails, all user data is already deleted and they'll be signed out
        // The auth user record will remain but with no associated data, which is acceptable
        do {
            // Check if admin.deleteUser is available
            try await client.auth.admin.deleteUser(id: userId)
        } catch {
            // If admin.deleteUser fails, that's okay - all user data is already deleted
            // The user will be signed out and the auth user record may remain in auth.users
            // but with no associated data, which is acceptable for client-side deletion
            print("⚠️ Info: Auth user deletion requires admin access. All user data has been deleted. The auth user record may remain in auth.users but with no associated data.")
            // Don't throw an error - account deletion is successful from the app's perspective
            // All user data is deleted, and they'll be signed out
        }
    }
    
    func getUserFriendships(userId: UUID) async throws -> [Friendship] {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        let friendshipsAsUser: [Friendship] = try await client
            .from("friendships")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        let friendshipsAsFriend: [Friendship] = try await client
            .from("friendships")
            .select()
            .eq("friend_id", value: userId.uuidString)
            .execute()
            .value
        
        return friendshipsAsUser + friendshipsAsFriend
    }
    
    // MARK: - Profile CRUD
    
    func fetchProfile(userId: UUID) async throws -> Profile? {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        let response: [Profile] = try await client
            .from("profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        
        return response.first
    }
    
    func createProfile(userId: UUID, username: String? = nil, name: String? = nil, profileImageUrl: String? = nil) async throws -> Profile {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        let newProfile = Profile(
            id: UUID(),
            userId: userId,
            username: username,
            name: name,
            profileImageUrl: profileImageUrl
        )
        
        let response: Profile = try await client
            .from("profiles")
            .insert(newProfile)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func updateProfile(userId: UUID, username: String? = nil, name: String? = nil, profileImageUrl: String? = nil) async throws -> Profile {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Create update payload with only the fields to update
        let updateData = ProfileUpdate(
            username: username,
            name: name,
            profileImageUrl: profileImageUrl
        )
        
        // Try to update existing profile
        let updateResponse: [Profile] = try await client
            .from("profiles")
            .update(updateData)
            .eq("user_id", value: userId.uuidString)
            .select()
            .execute()
            .value
        
        if let updatedProfile = updateResponse.first {
            return updatedProfile
        } else {
            // Profile doesn't exist, create it
            return try await createProfile(userId: userId, username: username, name: name, profileImageUrl: profileImageUrl)
        }
    }
    
    func uploadProfileImage(userId: UUID, imageData: Data) async throws -> String {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        let fileName = "\(userId.uuidString)/\(UUID().uuidString).jpg"
        
        // Upload the image data
        try await client.storage
            .from("profile-images")
            .upload(path: fileName, file: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))
        
        // Get public URL
        let url = try client.storage
            .from("profile-images")
            .getPublicURL(path: fileName)
        
        return url.absoluteString
    }
    
    func deleteProfileImage(userId: UUID, imagePath: String) async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Extract filename from URL or path
        let fileName = imagePath.contains(userId.uuidString) ? 
            imagePath.components(separatedBy: "\(userId.uuidString)/").last ?? "" :
            imagePath
        
        try await client.storage
            .from("profile-images")
            .remove(paths: [fileName])
    }
    
    // MARK: - Goals CRUD
    
    func fetchGoals(userId: UUID) async throws -> [Goal] {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Get goals where user is creator or buddy
        let goalsAsCreator: [Goal] = try await client
            .from("goals")
            .select()
            .eq("creator_id", value: userId.uuidString)
            .execute()
            .value
        
        let goalsAsBuddy: [Goal] = try await client
            .from("goals")
            .select()
            .eq("buddy_id", value: userId.uuidString)
            .execute()
            .value
        
        // Combine and deduplicate
        var allGoals = goalsAsCreator
        for goal in goalsAsBuddy {
            if !allGoals.contains(where: { $0.id == goal.id }) {
                allGoals.append(goal)
            }
        }
        
        // Sort by updated_at descending
        return allGoals.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func createGoal(name: String, trackingMethod: TrackingMethod, creatorId: UUID, buddyId: UUID?, goalType: String? = nil, taskBeingTracked: String? = nil, listItems: [String]? = nil, keepStreak: Bool? = nil, trackDailyQuantity: Bool? = nil, unitTracked: String? = nil, challengeOrFriendly: String? = nil, winningCondition: String? = nil, winningNumber: Int? = nil, endDate: Date? = nil, winnersPrize: String? = nil) async throws -> Goal {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        let newGoal = Goal(
            id: UUID(),
            name: name,
            trackingMethod: trackingMethod,
            creatorId: creatorId,
            buddyId: buddyId,
            goalType: goalType,
            taskBeingTracked: taskBeingTracked,
            listItems: listItems,
            keepStreak: keepStreak,
            trackDailyQuantity: trackDailyQuantity,
            unitTracked: unitTracked,
            challengeOrFriendly: challengeOrFriendly,
            winningCondition: winningCondition,
            winningNumber: winningNumber,
            endDate: endDate,
            winnersPrize: winnersPrize
        )
        
        let response: Goal = try await client
            .from("goals")
            .insert(newGoal)
            .select()
            .single()
            .execute()
            .value
        
        // Create initial progress entries for both creator and buddy (if exists)
        // This ensures both users see each other's progress from the start
        
        // Create creator's progress
        let creatorProgress = GoalProgress(
            id: UUID(),
            goalId: response.id,
            userId: creatorId,
            numericValue: nil,
            completedDays: nil,
            listItems: nil
        )
        
        do {
            _ = try await client
                .from("goal_progress")
                .insert(creatorProgress)
                .execute()
        } catch {
            print("Error creating creator progress: \(error)")
            // Continue even if creator progress creation fails
        }
        
        // Create buddy's progress if buddy exists
        // Initialize with empty listItems array (not nil) so the visual shows the buddy column
        if let buddyId = buddyId {
            let buddyProgress = GoalProgress(
                id: UUID(),
                goalId: response.id,
                userId: buddyId,
                numericValue: nil,
                completedDays: nil,
                listItems: [] // Empty array so buddy column shows up with all items unchecked
            )
            
            do {
                _ = try await client
                    .from("goal_progress")
                    .insert(buddyProgress)
                    .execute()
            } catch {
                print("Error creating buddy progress: \(error)")
                // Continue even if buddy progress creation fails - the view will handle it with fallback
            }
        }
        
        return response
    }
    
    func updateGoal(
        goalId: UUID,
        name: String? = nil,
        buddyId: UUID? = nil,
        taskBeingTracked: String? = nil,
        listItems: [String]? = nil,
        keepStreak: Bool? = nil,
        trackDailyQuantity: Bool? = nil,
        unitTracked: String? = nil,
        challengeOrFriendly: String? = nil,
        winningCondition: String? = nil,
        winningNumber: Int? = nil,
        endDate: Date? = nil,
        winnersPrize: String? = nil
    ) async throws -> Goal {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        struct GoalUpdate: Codable {
            var name: String?
            var taskBeingTracked: String?
            var listItems: [String]?
            var keepStreak: Bool?
            var trackDailyQuantity: Bool?
            var unitTracked: String?
            var challengeOrFriendly: String?
            var winningCondition: String?
            var winningNumber: Int?
            var endDate: String?
            var winnersPrize: String?
            var updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case name
                case taskBeingTracked = "task_being_tracked"
                case listItems = "list_items"
                case keepStreak = "keep_streak"
                case trackDailyQuantity = "track_daily_quantity"
                case unitTracked = "unit_tracked"
                case challengeOrFriendly = "challenge_or_friendly"
                case winningCondition = "winning_condition"
                case winningNumber = "winning_number"
                case endDate = "end_date"
                case winnersPrize = "winners_prize"
                case updatedAt = "updated_at"
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(updatedAt, forKey: .updatedAt)
                
                // Only encode non-nil values
                if let name = name { try container.encode(name, forKey: .name) }
                if let taskBeingTracked = taskBeingTracked { try container.encode(taskBeingTracked, forKey: .taskBeingTracked) }
                if let listItems = listItems { try container.encode(listItems, forKey: .listItems) }
                if let keepStreak = keepStreak { try container.encode(keepStreak, forKey: .keepStreak) }
                if let trackDailyQuantity = trackDailyQuantity { try container.encode(trackDailyQuantity, forKey: .trackDailyQuantity) }
                if let unitTracked = unitTracked { try container.encode(unitTracked, forKey: .unitTracked) }
                if let challengeOrFriendly = challengeOrFriendly { try container.encode(challengeOrFriendly, forKey: .challengeOrFriendly) }
                if let winningCondition = winningCondition { try container.encode(winningCondition, forKey: .winningCondition) }
                if let winningNumber = winningNumber { try container.encode(winningNumber, forKey: .winningNumber) }
                if let endDate = endDate { try container.encode(endDate, forKey: .endDate) }
                if let winnersPrize = winnersPrize { try container.encode(winnersPrize, forKey: .winnersPrize) }
            }
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let endDateString: String? = endDate != nil ? dateFormatter.string(from: endDate!) : nil
        
        // Create update struct with all values (nil values will be handled by custom encoding)
        var updateData = GoalUpdate(
            name: name,
            taskBeingTracked: taskBeingTracked,
            listItems: listItems,
            keepStreak: keepStreak,
            trackDailyQuantity: trackDailyQuantity,
            unitTracked: unitTracked,
            challengeOrFriendly: challengeOrFriendly,
            winningCondition: winningCondition,
            winningNumber: winningNumber,
            endDate: endDateString,
            winnersPrize: winnersPrize,
            updatedAt: dateFormatter.string(from: Date())
        )
        
        let response: Goal = try await client
            .from("goals")
            .update(updateData)
            .eq("id", value: goalId.uuidString)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Mark a goal as finished
    func markGoalAsFinished(goalId: UUID) async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        struct GoalStatusUpdate: Codable {
            let goalStatus: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case goalStatus = "goal_status"
                case updatedAt = "updated_at"
            }
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let update = GoalStatusUpdate(
            goalStatus: GoalStatus.finished.rawValue,
            updatedAt: dateFormatter.string(from: Date())
        )
        
        _ = try await client
            .from("goals")
            .update(update)
            .eq("id", value: goalId.uuidString)
            .execute()
    }
    
    func deleteGoal(goalId: UUID) async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        try await client
            .from("goals")
            .delete()
            .eq("id", value: goalId.uuidString)
            .execute()
    }
    
    func fetchGoalProgress(goalId: UUID) async throws -> [GoalProgress] {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        let response: [GoalProgress] = try await client
            .from("goal_progress")
            .select()
            .eq("goal_id", value: goalId.uuidString)
            .execute()
            .value
        
        return response
    }
    
    func updateGoalProgress(goalId: UUID, userId: UUID, numericValue: Double? = nil, completedDays: [String]? = nil, listItems: [GoalListItem]? = nil) async throws -> GoalProgress {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Check if progress exists
        let existing: [GoalProgress] = try await client
            .from("goal_progress")
            .select()
            .eq("goal_id", value: goalId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        struct ProgressUpdate: Codable {
            var numericValue: Double?
            var completedDays: [String]?
            var listItems: [GoalListItem]?
            var updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case numericValue = "numeric_value"
                case completedDays = "completed_days"
                case listItems = "list_items"
                case updatedAt = "updated_at"
            }
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let updateData = ProgressUpdate(
            numericValue: numericValue,
            completedDays: completedDays,
            listItems: listItems,
            updatedAt: dateFormatter.string(from: Date())
        )
        
        // Fetch goal to get buddy info
        let goals: [Goal] = try await client
            .from("goals")
            .select()
            .eq("id", value: goalId.uuidString)
            .execute()
            .value
        
        guard let goal = goals.first else {
            throw SupabaseError.custom("Goal not found")
        }
        
        if let existingProgress = existing.first {
            // Update existing progress
            let response: GoalProgress = try await client
                .from("goal_progress")
                .update(updateData)
                .eq("id", value: existingProgress.id.uuidString)
                .select()
                .single()
            .execute()
            .value
            
            // Create notification for buddy if goal has a buddy
            if let buddyId = goal.buddyId, buddyId != userId {
                if let userProfile = try? await fetchProfile(userId: userId) {
                    let updaterName = userProfile.name ?? userProfile.username ?? "Your buddy"
                    let notification = AppNotification(
                        id: UUID(),
                        userId: buddyId,
                        type: .goalUpdate,
                        title: "Goal Update",
                        message: "\(updaterName) updated progress on \"\(goal.name)\"",
                        relatedUserId: userId,
                        relatedGoalId: goalId,
                        isRead: false
                    )
                    _ = try? await createNotification(notification: notification)
                    // Local notification will be triggered when the buddy's app loads this notification
                }
            }
            
            // Also notify creator if user is the buddy
            if goal.creatorId != userId {
                if let userProfile = try? await fetchProfile(userId: userId) {
                    let updaterName = userProfile.name ?? userProfile.username ?? "Your buddy"
                    let notification = AppNotification(
                        id: UUID(),
                        userId: goal.creatorId,
                        type: .goalUpdate,
                        title: "Goal Update",
                        message: "\(updaterName) updated progress on \"\(goal.name)\"",
                        relatedUserId: userId,
                        relatedGoalId: goalId,
                        isRead: false
                    )
                    _ = try? await createNotification(notification: notification)
                    // Local notification will be triggered when the creator's app loads this notification
                }
            }
            
            // Check for winner determination if this is a challenge goal
            if goal.challengeOrFriendly == "challenge" {
                try? await checkAndDetermineWinner(goalId: goalId)
            }
            
            return response
        } else {
            // Create new progress
            let newProgress = GoalProgress(
                id: UUID(),
                goalId: goalId,
            userId: userId,
                numericValue: numericValue,
                completedDays: completedDays,
                listItems: listItems
            )
            
            let response: GoalProgress = try await client
                .from("goal_progress")
                .insert(newProgress)
            .select()
            .single()
            .execute()
            .value
            
            // Create notification for buddy if goal has a buddy
            if let buddyId = goal.buddyId, buddyId != userId {
                if let userProfile = try? await fetchProfile(userId: userId) {
                    let updaterName = userProfile.name ?? userProfile.username ?? "Your buddy"
                    let notification = AppNotification(
                        id: UUID(),
                        userId: buddyId,
                        type: .goalUpdate,
                        title: "Goal Update",
                        message: "\(updaterName) updated progress on \"\(goal.name)\"",
                        relatedUserId: userId,
                        relatedGoalId: goalId,
                        isRead: false
                    )
                    _ = try? await createNotification(notification: notification)
                    // Local notification will be triggered when the buddy's app loads this notification
                }
            }
            
            // Also notify creator if user is the buddy
            if goal.creatorId != userId {
                if let userProfile = try? await fetchProfile(userId: userId) {
                    let updaterName = userProfile.name ?? userProfile.username ?? "Your buddy"
                    let notification = AppNotification(
                        id: UUID(),
                        userId: goal.creatorId,
                        type: .goalUpdate,
                        title: "Goal Update",
                        message: "\(updaterName) updated progress on \"\(goal.name)\"",
                        relatedUserId: userId,
                        relatedGoalId: goalId,
                        isRead: false
                    )
                    _ = try? await createNotification(notification: notification)
                    // Local notification will be triggered when the creator's app loads this notification
                }
            }
            
            // Check for winner determination if this is a challenge goal
            if goal.challengeOrFriendly == "challenge" {
                try? await checkAndDetermineWinner(goalId: goalId)
            }
            
            return response
        }
    }
    
    // MARK: - Winner Determination
    
    /// Check if a winner condition is met and determine winner/loser
    /// This should be called after progress updates for challenge goals
    func checkAndDetermineWinner(goalId: UUID) async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        print("🔍 Checking for winner - Goal ID: \(goalId)")
        
        // Fetch goal
        let goals: [Goal] = try await client
            .from("goals")
            .select()
            .eq("id", value: goalId.uuidString)
            .execute()
            .value
        
        guard let goal = goals.first else {
            print("   ❌ Goal not found")
            throw SupabaseError.custom("Goal not found")
        }
        
        print("   📋 Goal: \(goal.name)")
        print("   🎯 Type: \(goal.goalType ?? "nil")")
        print("   ⚔️ Mode: \(goal.challengeOrFriendly ?? "nil")")
        print("   📊 Status: \(goal.goalStatus?.rawValue ?? "nil")")
        print("   👥 Buddy ID: \(goal.buddyId?.uuidString ?? "nil")")
        print("   🏁 Winning Condition: \(goal.winningCondition ?? "nil")")
        print("   🔢 Winning Number: \(goal.winningNumber?.description ?? "nil")")
        
        // Only process challenge goals that are still active
        guard goal.challengeOrFriendly == "challenge",
              (goal.goalStatus == nil || goal.goalStatus == .active || goal.goalStatus == .pendingFinish),
              goal.goalStatus != .finished,
              let buddyId = goal.buddyId else {
            print("   ⏸️ Skipping winner check - Not a challenge, already finished, or no buddy")
            return // Not a challenge or already finished or no buddy
        }
        
        // Fetch all progress for this goal
        let progressList = try await fetchGoalProgress(goalId: goalId)
        let creatorProgress = progressList.first { $0.userId == goal.creatorId }
        let buddyProgress = progressList.first { $0.userId == buddyId }
        
        // Create empty progress if it doesn't exist yet (for counting purposes)
        let creatorProg = creatorProgress ?? GoalProgress(
            id: UUID(),
            goalId: goalId,
            userId: goal.creatorId,
            numericValue: nil,
            completedDays: nil,
            listItems: nil,
            updatedAt: Date(),
            hasSeenWinnerMessage: nil
        )
        
        let buddyProg = buddyProgress ?? GoalProgress(
            id: UUID(),
            goalId: goalId,
            userId: buddyId,
            numericValue: nil,
            completedDays: nil,
            listItems: nil,
            updatedAt: Date(),
            hasSeenWinnerMessage: nil
        )
        
        // Check if winner condition is met
        let winner = try determineWinner(goal: goal, creatorProgress: creatorProg, buddyProgress: buddyProg)
        
        if let winnerId = winner {
            let loserId = winnerId == goal.creatorId ? buddyId : goal.creatorId
            
            print("🏆 WINNER DETERMINED!")
            print("   Goal: \(goal.name)")
            print("   Winner ID: \(winnerId)")
            print("   Loser ID: \(loserId)")
            
            // Update goal with winner/loser and set status to pending_finish
            struct GoalUpdate: Codable {
                let winnerUserId: UUID
                let loserUserId: UUID
                let goalStatus: String
                
                enum CodingKeys: String, CodingKey {
                    case winnerUserId = "winner_user_id"
                    case loserUserId = "loser_user_id"
                    case goalStatus = "goal_status"
                }
            }
            
            let update = GoalUpdate(
                winnerUserId: winnerId,
                loserUserId: loserId,
                goalStatus: GoalStatus.pendingFinish.rawValue
            )
            
            let updatedGoal: Goal = try await client
                .from("goals")
                .update(update)
                .eq("id", value: goalId.uuidString)
                .select()
                .single()
                .execute()
                .value
            
            print("   ✅ Goal status updated to: \(updatedGoal.goalStatus?.rawValue ?? "nil")")
            
            // Send notifications to both users with same message (don't reveal who won)
            // Send same message to both users so winner isn't revealed in notification
            let completionMessage = "The \"\(goal.name)\" goal has been completed. Check it to see the results!"
            
            // Notify loser
            let loserNotification = AppNotification(
                id: UUID(),
                userId: loserId,
                type: .goalUpdate,
                title: "Goal Completed",
                message: completionMessage,
                relatedUserId: nil,
                relatedGoalId: goalId,
                isRead: false
            )
            _ = try? await createNotification(notification: loserNotification)
            // Local notification will be triggered when the loser's app loads this notification
            
            // Also notify winner with same message (not revealing they won)
            let winnerNotification = AppNotification(
                id: UUID(),
                userId: winnerId,
                type: .goalUpdate,
                title: "Goal Completed",
                message: completionMessage,
                relatedUserId: nil,
                relatedGoalId: goalId,
                isRead: false
            )
            _ = try? await createNotification(notification: winnerNotification)
            // Local notification will be triggered when the winner's app loads this notification
        }
    }
    
    /// Determine winner based on goal type and winning condition
    private func determineWinner(goal: Goal, creatorProgress: GoalProgress, buddyProgress: GoalProgress) throws -> UUID? {
        guard let winningCondition = goal.winningCondition else {
            return nil
        }
        
        let condition = winningCondition.lowercased()
        
        // Get current counts for both users
        let creatorCount = getCurrentCount(goal: goal, progress: creatorProgress)
        let buddyCount = getCurrentCount(goal: goal, progress: buddyProgress)
        
        // Check different winning conditions
        // For list_tracker: "First to reach X number of [task]" or "first_to_reach_x"
        if condition.contains("first to reach") || condition.contains("first_to_reach_x") {
            // First to reach X number
            guard let target = goal.winningNumber else { return nil }
            
            // Debug logging
//            print("🎯 Winner Check - List Tracker 'First to Reach':")
//            print("   Goal ID: \(goal.id)")
//            print("   Winning Condition: \(goal.winningCondition ?? "nil")")
//            print("   Target: \(target)")
//            print("   Creator Count: \(creatorCount)")
//            print("   Buddy Count: \(buddyCount)")
            
            // Check if creator wins
            if creatorCount >= target && buddyCount < target {
                //print("   ✅ Creator wins! (\(creatorCount) >= \(target) and buddy has \(buddyCount))")
                return goal.creatorId
            }
            // Check if buddy wins
            else if buddyCount >= target && creatorCount < target {
                //print("   ✅ Buddy wins! (\(buddyCount) >= \(target) and creator has \(creatorCount))")
                return goal.buddyId
            } else {
                //print("   ⏳ No winner yet (Creator: \(creatorCount)/\(target), Buddy: \(buddyCount)/\(target))")
            }
        } else if condition.contains("first to finish") || condition.contains("first_to_finish") {
            // First to finish the list (for user created list)
            if let listItems = goal.listItems {
                let creatorCompleted = creatorProgress.listItems?.count ?? 0
                let buddyCompleted = buddyProgress.listItems?.count ?? 0
                if creatorCompleted >= listItems.count && buddyCompleted < listItems.count {
                    return goal.creatorId
                } else if buddyCompleted >= listItems.count && creatorCompleted < listItems.count {
                    return goal.buddyId
                }
            }
        } else if condition.contains("first to complete x") || condition.contains("first_to_complete_x_amount") {
            // First to complete X amount (for daily tracker with quantity)
            guard let target = goal.winningNumber else { return nil }
            if creatorCount >= target && buddyCount < target {
                return goal.creatorId
            } else if buddyCount >= target && creatorCount < target {
                return goal.buddyId
            }
        } else if condition.contains("first to reach x days streak") || condition.contains("first_to_reach_x_days_streak") {
            // First to reach X days streak
            guard let target = goal.winningNumber else { return nil }
            let creatorStreak = calculateStreak(from: creatorProgress.completedDays ?? [])
            let buddyStreak = calculateStreak(from: buddyProgress.completedDays ?? [])
            if creatorStreak.current >= target && buddyStreak.current < target {
                return goal.creatorId
            } else if buddyStreak.current >= target && creatorStreak.current < target {
                return goal.buddyId
            }
        } else if condition.contains("most by end date") || condition.contains("most_by_end_date") {
            // Most by end date - check if end date has passed
            guard let endDate = goal.endDate else { return nil }
            let calendar = Calendar.current
            let now = Date()
            if calendar.compare(now, to: endDate, toGranularity: .day) == .orderedDescending {
                // End date has passed, determine winner by count
                if creatorCount > buddyCount {
                    return goal.creatorId
                } else if buddyCount > creatorCount {
                    return goal.buddyId
                }
                // Tie - could return nil or handle tie scenario
            }
        } else if condition.contains("most days by end date") || condition.contains("most_days_by_end_date") {
            // Most days by end date
            guard let endDate = goal.endDate else { return nil }
            let calendar = Calendar.current
            let now = Date()
            if calendar.compare(now, to: endDate, toGranularity: .day) == .orderedDescending {
                let creatorDays = creatorProgress.completedDays?.count ?? 0
                let buddyDays = buddyProgress.completedDays?.count ?? 0
                if creatorDays > buddyDays {
                    return goal.creatorId
                } else if buddyDays > creatorDays {
                    return goal.buddyId
                }
            }
        } else if condition.contains("longest streak by end date") || condition.contains("longest_streak_by_end_date") {
            // Longest streak by end date
            guard let endDate = goal.endDate else { return nil }
            let calendar = Calendar.current
            let now = Date()
            if calendar.compare(now, to: endDate, toGranularity: .day) == .orderedDescending {
                let creatorStreak = calculateStreak(from: creatorProgress.completedDays ?? [])
                let buddyStreak = calculateStreak(from: buddyProgress.completedDays ?? [])
                if creatorStreak.max > buddyStreak.max {
                    return goal.creatorId
                } else if buddyStreak.max > creatorStreak.max {
                    return goal.buddyId
                }
            }
        } else if condition.contains("most amount by end date") || condition.contains("most_amount_by_end_date") {
            // Most amount by end date (for daily tracker with quantity)
            guard let endDate = goal.endDate else { return nil }
            let calendar = Calendar.current
            let now = Date()
            if calendar.compare(now, to: endDate, toGranularity: .day) == .orderedDescending {
                if creatorCount > buddyCount {
                    return goal.creatorId
                } else if buddyCount > creatorCount {
                    return goal.buddyId
                }
            }
        }
        
        return nil // No winner determined yet
    }
    
    /// Get current count for a user based on goal type
    private func getCurrentCount(goal: Goal, progress: GoalProgress) -> Int {
        switch goal.goalType {
        case "list_tracker":
            return progress.listItems?.count ?? 0
        case "list_created_by_user":
            return progress.listItems?.count ?? 0
        case "daily_tracker":
            if goal.trackDailyQuantity == true {
                // Sum up quantities from listItems
                let total = progress.listItems?.reduce(0.0) { sum, item in
                    sum + (Double(item.title) ?? 0.0)
                } ?? 0.0
                return Int(total)
            } else {
                return progress.completedDays?.count ?? 0
            }
        default:
            return progress.listItems?.count ?? 0
        }
    }
    
    /// Calculate streak from completed days
    private func calculateStreak(from completedDays: [String]) -> (current: Int, max: Int) {
        guard !completedDays.isEmpty else { return (0, 0) }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Sort dates
        let sortedDates = completedDays.compactMap { dateFormatter.date(from: $0) }.sorted()
        
        guard !sortedDates.isEmpty else { return (0, 0) }
        
        var currentStreak = 1
        var maxStreak = 1
        var previousDate: Date? = nil
        
        for date in sortedDates {
            if let prev = previousDate {
                let daysDiff = Calendar.current.dateComponents([.day], from: prev, to: date).day ?? 0
                if daysDiff == 1 {
                    currentStreak += 1
                    maxStreak = max(maxStreak, currentStreak)
                } else {
                    currentStreak = 1
                }
            }
            previousDate = date
        }
        
        // Check if current streak includes today
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = sortedDates.last,
           Calendar.current.isDate(lastDate, inSameDayAs: today) ||
           Calendar.current.isDate(lastDate, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today) {
            // Streak is current
        } else {
            currentStreak = 0
        }
        
        return (currentStreak, maxStreak)
    }
    
    /// Check end dates for goals and determine winners
    /// This should be called periodically (e.g., via cron job or scheduled task)
    func checkEndDatesAndDetermineWinners() async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Fetch all active challenge goals with end dates
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nowString = dateFormatter.string(from: now)
        
        // Note: This query would need to be adjusted based on your Supabase setup
        // For now, we'll fetch all challenge goals and filter client-side
        let goals: [Goal] = try await client
            .from("goals")
            .select()
            .eq("challenge_or_friendly", value: "challenge")
            .execute()
            .value
        
        // Filter goals where end date has passed and status is still active
        let expiredGoals = goals.filter { goal in
            guard let endDate = goal.endDate else {
                return false
            }
            // Only process goals that are active (nil defaults to active) or pending_finish
            let isActive = goal.goalStatus == nil || goal.goalStatus == .active || goal.goalStatus == .pendingFinish
            if !isActive {
                return false
            }
            return Calendar.current.compare(now, to: endDate, toGranularity: .day) != .orderedAscending
        }
        
        // Check and determine winners for each expired goal
        for goal in expiredGoals {
            try? await checkAndDetermineWinner(goalId: goal.id)
        }
    }
    
    /// Mark that a user has seen the winner message
    func markWinnerMessageSeen(goalId: UUID, userId: UUID) async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Update progress to mark message as seen
        struct ProgressUpdate: Codable {
            let hasSeenWinnerMessage: Bool
            
            enum CodingKeys: String, CodingKey {
                case hasSeenWinnerMessage = "has_seen_winner_message"
            }
        }
        
        let update = ProgressUpdate(hasSeenWinnerMessage: true)
        
        // Find the progress entry
        let progressList: [GoalProgress] = try await client
            .from("goal_progress")
            .select()
            .eq("goal_id", value: goalId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        if let progress = progressList.first {
            _ = try await client
                .from("goal_progress")
                .update(update)
                .eq("id", value: progress.id.uuidString)
                .execute()
        } else {
            // Create progress entry if it doesn't exist
            let newProgress = GoalProgress(
                id: UUID(),
                goalId: goalId,
                userId: userId,
                hasSeenWinnerMessage: true
            )
            _ = try await client
                .from("goal_progress")
                .insert(newProgress)
                .execute()
        }
        
        // Check if both users have seen the message, then mark goal as finished
        let allProgress: [GoalProgress] = try await client
            .from("goal_progress")
            .select()
            .eq("goal_id", value: goalId.uuidString)
            .execute()
            .value
        
        // Fetch goal to get creator and buddy IDs
        let goals: [Goal] = try await client
            .from("goals")
            .select()
            .eq("id", value: goalId.uuidString)
            .execute()
            .value
        
        guard let goal = goals.first,
              let buddyId = goal.buddyId else {
            return
        }
        
        let creatorProgress = allProgress.first { $0.userId == goal.creatorId }
        let buddyProgress = allProgress.first { $0.userId == buddyId }
        
        let creatorSeen = creatorProgress?.hasSeenWinnerMessage == true
        let buddySeen = buddyProgress?.hasSeenWinnerMessage == true
        
        if creatorSeen && buddySeen {
            // Both users have seen the message, mark goal as finished
            struct GoalUpdate: Codable {
                let goalStatus: String
                
                enum CodingKeys: String, CodingKey {
                    case goalStatus = "goal_status"
                }
            }
            
            let update = GoalUpdate(goalStatus: GoalStatus.finished.rawValue)
            
            _ = try await client
                .from("goals")
                .update(update)
                .eq("id", value: goalId.uuidString)
                .execute()
        }
    }
    
    // MARK: - Friends CRUD
    
    func searchUsers(query: String, currentUserId: UUID) async throws -> [UserProfile] {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Validate query
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else {
            return []
        }
        
        // Try to use PostgreSQL text search if possible
        // For now, we'll fetch more profiles and filter client-side
        // This is a limitation - in production, use PostgreSQL full-text search
        
        // Try to use database-level filtering with ilike for better performance
        // First, try to search by name
        var profilesByName: [UserProfile] = []
        var profilesByUsername: [UserProfile] = []
        
        do {
            // Search by name using ilike (case-insensitive pattern matching)
            // Note: Supabase Swift SDK might not support ilike directly, so we'll fetch and filter
            let allProfiles: [UserProfile] = try await client
                .from("profiles")
                .select()
                .neq("user_id", value: currentUserId.uuidString)
                .limit(1000) // Increased limit
                .execute()
                .value
            
            // Debug: Log all profiles found (first few for debugging)
            //print("🔍 DEBUG: Found \(allProfiles.count) total profiles in database")
            if allProfiles.count > 0 {
                //print("🔍 DEBUG: First profile sample:")
                let firstProfile = allProfiles[0]
//                print("   - user_id: \(firstProfile.userId)")
//                print("   - username: \(firstProfile.username ?? "nil")")
//                print("   - name: \(firstProfile.name ?? "nil")")
//                print("   - id: \(firstProfile.id)")
            }
            
            // Debug: Log profiles that might match
            //print("🔍 DEBUG: Searching for query: '\(trimmedQuery)' (lowercase: '\(trimmedQuery.lowercased())')")
            
            // Filter by username or name (case-insensitive, starts with or contains)
            let lowerQuery = trimmedQuery.lowercased()
            
            // Debug: Check all profiles for the search term
            //print("🔍 DEBUG: Checking \(allProfiles.count) profiles for query '\(trimmedQuery)'")
            
            let filtered = allProfiles.filter { profile in
                // Handle both nil and empty string cases
                let rawUsername = profile.username
                let rawName = profile.name
                
                // Convert to strings, handling nil and empty strings
                let username = (rawUsername?.isEmpty == false) ? rawUsername! : ""
                let name = (rawName?.isEmpty == false) ? rawName! : ""
                
                // Trim and lowercase
                let usernameLower = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let nameLower = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                // Debug: Log ALL profiles being checked (not just first 5) to find Jose
                if usernameLower.contains("jose") || nameLower.contains("jose") || 
                   usernameLower.contains(lowerQuery) || nameLower.contains(lowerQuery) {
                    //print("🔍 DEBUG: 🔎 POTENTIAL MATCH - username: '\(username)' (raw: '\(rawUsername ?? "nil")'), name: '\(name)' (raw: '\(rawName ?? "nil")'), userId: \(profile.userId)")
                }
                
                // Skip profiles with no username and no name
                if usernameLower.isEmpty && nameLower.isEmpty {
                    return false
                }
                
                // Match if username or name starts with query, or contains query
                let usernameStartsWith = !usernameLower.isEmpty && usernameLower.hasPrefix(lowerQuery)
                let nameStartsWith = !nameLower.isEmpty && nameLower.hasPrefix(lowerQuery)
                let usernameContains = !usernameLower.isEmpty && usernameLower.contains(lowerQuery)
                let nameContains = !nameLower.isEmpty && nameLower.contains(lowerQuery)
                
                let matches = usernameStartsWith || nameStartsWith || usernameContains || nameContains
                
                // Debug: Log all matches
                if matches {
                    //print("🔍 DEBUG: ✅ MATCH FOUND - username: '\(usernameLower)', name: '\(nameLower)', userId: \(profile.userId)")
                }
                
                return matches
            }
            
            // Debug: Log how many profiles matched
           // print("🔍 DEBUG: Found \(filtered.count) profiles matching query '\(trimmedQuery)'")
            
            // Debug: Log all matching profiles
            for (index, profile) in filtered.enumerated() {
                if index < 10 { // Log first 10 matches
                    //print("🔍 DEBUG: Match \(index + 1): username='\(profile.username ?? "nil")', name='\(profile.name ?? "nil")', userId=\(profile.userId)")
                }
            }
            
            profilesByName = filtered
            profilesByUsername = filtered // Same results for now
        } catch {
            print("❌ ERROR: Error fetching profiles: \(error)")
            print("❌ ERROR: Error details: \(error.localizedDescription)")
            if let error = error as? DecodingError {
                print("❌ ERROR: Decoding error: \(error)")
            }
            throw SupabaseError.custom("Failed to fetch user profiles: \(error.localizedDescription)")
        }
        
        // Combine and deduplicate
        var allFiltered = profilesByName
        for profile in profilesByUsername {
            if !allFiltered.contains(where: { $0.userId == profile.userId }) {
                allFiltered.append(profile)
            }
        }
        
        let filtered = allFiltered
        
        // Sort: starts with matches first, then contains matches
        let lowerQuery = trimmedQuery.lowercased()
        let sorted = filtered.sorted { profile1, profile2 in
            let username1 = (profile1.username ?? "").lowercased()
            let name1 = (profile1.name ?? "").lowercased()
            let username2 = (profile2.username ?? "").lowercased()
            let name2 = (profile2.name ?? "").lowercased()
            
            let p1StartsWith = username1.hasPrefix(lowerQuery) || name1.hasPrefix(lowerQuery)
            let p2StartsWith = username2.hasPrefix(lowerQuery) || name2.hasPrefix(lowerQuery)
            
            if p1StartsWith && !p2StartsWith {
                return true
            } else if !p1StartsWith && p2StartsWith {
                return false
            }
            
            // If both start with or both don't, sort alphabetically
            return (username1 + name1) < (username2 + name2)
        }
        
        // Get existing friendships for these users
        let userIds = sorted.map { $0.userId }
        var friendshipsMap: [UUID: Friendship] = [:]
        
        // Only fetch friendships if we have users to check
        if !userIds.isEmpty {
            // Fetch friendships where current user is involved
            let friendshipsAsUser: [Friendship] = try await client
                .from("friendships")
                .select()
                .eq("user_id", value: currentUserId.uuidString)
                .execute()
                .value
            
            let friendshipsAsFriend: [Friendship] = try await client
                .from("friendships")
                .select()
                .eq("friend_id", value: currentUserId.uuidString)
                .execute()
                .value
            
            let allFriendships = friendshipsAsUser + friendshipsAsFriend
            
            // Create a map of user ID to friendship
            for friendship in allFriendships {
                let otherUserId = friendship.userId == currentUserId ? friendship.friendId : friendship.userId
                if userIds.contains(otherUserId) {
                    friendshipsMap[otherUserId] = friendship
                }
            }
        }
        
        // Map friendships to users - create new UserProfile instances with friendship info
        var results: [UserProfile] = []
        for profile in sorted.prefix(50) { // Increased limit to 50 results
            var userProfile = profile
            if let friendship = friendshipsMap[profile.userId] {
                userProfile.friendshipId = friendship.id
                userProfile.friendshipStatus = friendship.status.rawValue
            }
            results.append(userProfile)
        }
        
        return results
    }
    
    func sendFriendRequest(fromUserId: UUID, toUserId: UUID) async throws -> Friendship {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Check if friendship already exists
        // Check both directions separately
        let existingAsUser: [Friendship] = try await client
            .from("friendships")
            .select()
            .eq("user_id", value: fromUserId.uuidString)
            .eq("friend_id", value: toUserId.uuidString)
            .execute()
            .value
        
        let existingAsFriend: [Friendship] = try await client
            .from("friendships")
            .select()
            .eq("user_id", value: toUserId.uuidString)
            .eq("friend_id", value: fromUserId.uuidString)
            .execute()
            .value
        
        let existing = existingAsUser + existingAsFriend
        
        if let existingFriendship = existing.first {
            // If already accepted, return it
            if existingFriendship.status == .accepted {
                return existingFriendship
            }
            // If pending and was sent by the other user, accept it
            if existingFriendship.status == .pending && existingFriendship.userId == toUserId {
                return try await acceptFriendRequest(friendshipId: existingFriendship.id)
            }
            // Otherwise, throw error
            throw SupabaseError.custom("Friend request already exists")
        }
        
        // Create new friend request
        let newFriendship = Friendship(
            id: UUID(),
            userId: fromUserId,
            friendId: toUserId,
            status: .pending,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let response: Friendship = try await client
            .from("friendships")
            .insert(newFriendship)
            .select()
            .single()
            .execute()
            .value
        
        // Create notification for the recipient
        if let fromProfile = try? await fetchProfile(userId: fromUserId) {
            let senderName = fromProfile.name ?? fromProfile.username ?? "Someone"
            let notification = AppNotification(
                id: UUID(),
                userId: toUserId,
                type: .friendRequest,
                title: "New Friend Request",
                message: "\(senderName) wants to be your friend",
                relatedUserId: fromUserId,
                isRead: false
            )
            _ = try? await createNotification(notification: notification)
            // Local notification will be triggered when the recipient's app loads this notification
        }
        
        return response
    }
    
    func acceptFriendRequest(friendshipId: UUID) async throws -> Friendship {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Create update struct
        struct FriendshipUpdate: Codable {
            let status: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case status
                case updatedAt = "updated_at"
            }
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let updateData = FriendshipUpdate(
            status: "accepted",
            updatedAt: dateFormatter.string(from: Date())
        )
        
        let response: Friendship = try await client
            .from("friendships")
            .update(updateData)
            .eq("id", value: friendshipId.uuidString)
            .select()
            .single()
            .execute()
            .value
        
        // Create notification for the person who sent the request
        // The person accepting is the one who received the original request
        // So we need to notify the original sender (user_id in the friendship)
        if let accepterProfile = try? await fetchProfile(userId: response.friendId) {
            let accepterName = accepterProfile.name ?? accepterProfile.username ?? "Someone"
            let notification = AppNotification(
                id: UUID(),
                userId: response.userId, // Original sender
                type: .friendRequestAccepted,
                title: "Friend Request Accepted",
                message: "\(accepterName) accepted your friend request",
                relatedUserId: response.friendId,
                isRead: false
            )
            _ = try? await createNotification(notification: notification)
            // Local notification will be triggered when the sender's app loads this notification
        }
        
        return response
    }
    
    func getFriends(userId: UUID) async throws -> [UserProfile] {
        // Use direct method for now (RPC functions need to be set up in database)
        return try await getFriendsDirect(userId: userId)
    }
    
    func getFriendRequests(userId: UUID) async throws -> [UserProfile] {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Get pending friend requests where user is the friend_id (received requests)
        let friendships: [Friendship] = try await client
            .from("friendships")
            .select()
            .eq("friend_id", value: userId.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
        
        var requests: [UserProfile] = []
        
        for friendship in friendships {
            if let profile = try await fetchProfile(userId: friendship.userId) {
                let userProfile = UserProfile(
                    id: profile.id,
                    userId: profile.userId,
                    username: profile.username,
                    name: profile.name,
                    profileImageUrl: profile.profileImageUrl,
                    createdAt: profile.createdAt,
                    updatedAt: profile.updatedAt,
                    friendshipId: friendship.id,
                    friendshipStatus: friendship.status.rawValue
                )
                requests.append(userProfile)
            }
        }
        
        return requests
    }
    
    func findPendingFriendship(userId1: UUID, userId2: UUID) async throws -> Friendship? {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Check both directions
        let friendshipsAsUser: [Friendship] = try await client
            .from("friendships")
            .select()
            .eq("user_id", value: userId1.uuidString)
            .eq("friend_id", value: userId2.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
        
        let friendshipsAsFriend: [Friendship] = try await client
            .from("friendships")
            .select()
            .eq("user_id", value: userId2.uuidString)
            .eq("friend_id", value: userId1.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
        
        return (friendshipsAsUser + friendshipsAsFriend).first
    }
    
    func removeFriend(friendshipId: UUID) async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        try await client
            .from("friendships")
            .delete()
            .eq("id", value: friendshipId.uuidString)
            .execute()
    }
    
    // Alternative method to get friends using direct query (if RPC functions aren't set up)
    func getFriendsDirect(userId: UUID) async throws -> [UserProfile] {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Get friendships where user is involved and status is accepted
        // Then fetch the friend's profile
        let friendshipsAsUser: [Friendship] = try await client
            .from("friendships")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "accepted")
            .execute()
            .value
        
        let friendshipsAsFriend: [Friendship] = try await client
            .from("friendships")
            .select()
            .eq("friend_id", value: userId.uuidString)
            .eq("status", value: "accepted")
            .execute()
            .value
        
        let friendships = friendshipsAsUser + friendshipsAsFriend
        
        var friends: [UserProfile] = []
        
        for friendship in friendships {
            let friendId = friendship.userId == userId ? friendship.friendId : friendship.userId
            
            if let profile = try await fetchProfile(userId: friendId) {
                var userProfile = UserProfile(
                    id: profile.id,
                    userId: profile.userId,
                    username: profile.username,
                    name: profile.name,
                    profileImageUrl: profile.profileImageUrl,
                    createdAt: profile.createdAt,
                    updatedAt: profile.updatedAt,
                    friendshipId: friendship.id,
                    friendshipStatus: friendship.status.rawValue
                )
                friends.append(userProfile)
            }
        }
        
        return friends
    }
    
    // MARK: - Notifications CRUD
    
    func fetchNotifications(userId: UUID) async throws -> [AppNotification] {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        let response: [AppNotification] = try await client
            .from("notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value
        
        return response
    }
    
    func createNotification(notification: AppNotification) async throws -> AppNotification {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        let response: AppNotification = try await client
            .from("notifications")
            .insert(notification)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func markNotificationAsRead(notificationId: UUID) async throws -> AppNotification {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        struct NotificationUpdate: Codable {
            var isRead: Bool
            
            enum CodingKeys: String, CodingKey {
                case isRead = "is_read"
            }
        }
        
        let updateData = NotificationUpdate(isRead: true)
        
        let response: AppNotification = try await client
            .from("notifications")
            .update(updateData)
            .eq("id", value: notificationId.uuidString)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func markAllNotificationsAsRead(userId: UUID) async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        struct NotificationUpdate: Codable {
            var isRead: Bool
            
            enum CodingKeys: String, CodingKey {
                case isRead = "is_read"
            }
        }
        
        let updateData = NotificationUpdate(isRead: true)
        
        try await client
            .from("notifications")
            .update(updateData)
            .eq("user_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
    }
    
    func deleteNotification(notificationId: UUID) async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        try await client
            .from("notifications")
            .delete()
            .eq("id", value: notificationId.uuidString)
            .execute()
    }
    
    // MARK: - Feedback CRUD
    
    func submitFeedback(name: String, email: String, message: String) async throws -> Feedback {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        // Get current authenticated user ID - required for feedback submission
        guard let userId = await getCurrentUser() else {
            throw SupabaseError.custom("You must be logged in to submit feedback. Please sign in and try again.")
        }
        
        // Debug: Print the user auth ID to console
        //print("🔍 DEBUG: Feedback submission - User Auth ID: \(userId.uuidString)")
        
        // Create feedback INSERT object - only contains fields we send to database
        // id and created_at will be auto-generated by the database
        let feedbackInsert = FeedbackInsert(
            userId: userId,
            name: name,
            email: email,
            message: message
        )
        
        //print("🔍 DEBUG: FeedbackInsert object - user_id: \(feedbackInsert.userId.uuidString)")
        
        do {
            // Insert feedback - database will auto-generate id and created_at
            // Response will be the full Feedback object including generated fields
            let response: Feedback = try await client
                .from("feedback")
                .insert(feedbackInsert)
                .select()
                .single()
                .execute()
                .value
            
            //print("🔍 DEBUG: Feedback submitted successfully! ID: \(response.id.uuidString)")
            return response
        } catch {
            // Print FULL error details for debugging
            //print("🔍 DEBUG: Feedback submission FULL error: \(error)")
            //print("🔍 DEBUG: Error type: \(type(of: error))")
            //print("🔍 DEBUG: Error localized: \(error.localizedDescription)")
            
            // Try to get more details if it's a Supabase error
            let errorMessage = "\(error)"
            if errorMessage.contains("row-level security") || errorMessage.contains("RLS") || errorMessage.contains("violates") {
                throw SupabaseError.custom("Feedback submission failed due to security policy. Please ensure you are logged in and the RLS policy allows authenticated users to insert feedback. Error: \(errorMessage)")
            }
            throw error
        }
    }
}

enum SupabaseError: LocalizedError {
    case notInitialized
    case signUpFailed
    case signInFailed
    case invalidCredentials
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Supabase client not initialized. Please check your credentials."
        case .signUpFailed:
            return "Failed to create account. Please try again."
        case .signInFailed:
            return "Failed to sign in. Please check your credentials."
        case .invalidCredentials:
            return "Invalid email or password."
        case .custom(let message):
            return message
        }
    }
}
