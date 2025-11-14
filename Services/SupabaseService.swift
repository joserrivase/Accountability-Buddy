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
    
    func signUp(email: String, password: String) async throws {
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
    
    // MARK: - Books CRUD
    
    func fetchBooks(userId: UUID) async throws -> [Book] {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        let response: [Book] = try await client
            .from("books")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func addBook(title: String, userId: UUID) async throws -> Book {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        let newBook = Book(
            id: UUID(),
            title: title,
            userId: userId,
            createdAt: Date()
        )
        
        let response: Book = try await client
            .from("books")
            .insert(newBook)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func deleteBook(bookId: UUID) async throws {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        try await client
            .from("books")
            .delete()
            .eq("id", value: bookId.uuidString)
            .execute()
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
    
    func createGoal(name: String, trackingMethod: TrackingMethod, creatorId: UUID, buddyId: UUID?) async throws -> Goal {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        let newGoal = Goal(
            id: UUID(),
            name: name,
            trackingMethod: trackingMethod,
            creatorId: creatorId,
            buddyId: buddyId
        )
        
        let response: Goal = try await client
            .from("goals")
            .insert(newGoal)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func updateGoal(goalId: UUID, name: String? = nil, buddyId: UUID? = nil) async throws -> Goal {
        guard let client = client else {
            throw SupabaseError.notInitialized
        }
        
        struct GoalUpdate: Codable {
            var name: String?
            var buddyId: UUID?
            var updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case name
                case buddyId = "buddy_id"
                case updatedAt = "updated_at"
            }
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var updateData = GoalUpdate(
            name: name,
            buddyId: buddyId,
            updatedAt: dateFormatter.string(from: Date())
        )
        
        // Only include non-nil values
        if name == nil {
            updateData.name = nil
        }
        if buddyId == nil {
            updateData.buddyId = nil
        }
        
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
    
    func updateGoalProgress(goalId: UUID, userId: UUID, numericValue: Double? = nil, completedDays: [String]? = nil, listItems: [String]? = nil) async throws -> GoalProgress {
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
            var listItems: [String]?
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
            
            return response
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
            print("🔍 DEBUG: Found \(allProfiles.count) total profiles in database")
            if allProfiles.count > 0 {
                print("🔍 DEBUG: First profile sample:")
                let firstProfile = allProfiles[0]
                print("   - user_id: \(firstProfile.userId)")
                print("   - username: \(firstProfile.username ?? "nil")")
                print("   - name: \(firstProfile.name ?? "nil")")
                print("   - id: \(firstProfile.id)")
            }
            
            // Debug: Log profiles that might match
            print("🔍 DEBUG: Searching for query: '\(trimmedQuery)' (lowercase: '\(trimmedQuery.lowercased())')")
            
            // Filter by username or name (case-insensitive, starts with or contains)
            let lowerQuery = trimmedQuery.lowercased()
            
            // Debug: Check all profiles for the search term
            print("🔍 DEBUG: Checking \(allProfiles.count) profiles for query '\(trimmedQuery)'")
            
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
                    print("🔍 DEBUG: 🔎 POTENTIAL MATCH - username: '\(username)' (raw: '\(rawUsername ?? "nil")'), name: '\(name)' (raw: '\(rawName ?? "nil")'), userId: \(profile.userId)")
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
                    print("🔍 DEBUG: ✅ MATCH FOUND - username: '\(usernameLower)', name: '\(nameLower)', userId: \(profile.userId)")
                }
                
                return matches
            }
            
            // Debug: Log how many profiles matched
            print("🔍 DEBUG: Found \(filtered.count) profiles matching query '\(trimmedQuery)'")
            
            // Debug: Log all matching profiles
            for (index, profile) in filtered.enumerated() {
                if index < 10 { // Log first 10 matches
                    print("🔍 DEBUG: Match \(index + 1): username='\(profile.username ?? "nil")', name='\(profile.name ?? "nil")', userId=\(profile.userId)")
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
