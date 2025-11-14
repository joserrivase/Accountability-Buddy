//
//  FriendsViewModel.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import Foundation
import SwiftUI

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [UserProfile] = []
    @Published var searchResults: [UserProfile] = []
    @Published var friendRequests: [UserProfile] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    private var userId: UUID?
    
    func setUserId(_ userId: UUID) {
        self.userId = userId
        Task {
            await loadFriends()
            await loadFriendRequests()
        }
    }
    
    func loadFriends() async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            friends = try await supabaseService.getFriends(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadFriendRequests() async {
        guard let userId = userId else { return }
        
        do {
            friendRequests = try await supabaseService.getFriendRequests(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func searchUsers(query: String) async {
        guard let userId = userId else {
            searchResults = []
            return
        }
        
        // Trim whitespace and check minimum length
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If query is too short, clear results but don't show error
        if trimmedQuery.isEmpty {
            searchResults = []
            isSearching = false
            return
        }
        
        // Require at least 2 characters for search
        if trimmedQuery.count < 2 {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        do {
            // Search users
            var results = try await supabaseService.searchUsers(query: trimmedQuery, currentUserId: userId)
            
            // Filter out users who are already friends (but keep pending/accepted status visible)
            // Actually, let's show all results with their status
            searchResults = results
        } catch {
            // Don't show cancellation errors as user-facing errors
            if error is CancellationError {
                // Task was cancelled, just return without updating UI
                return
            }
            
            // Only show actual errors
            print("Search error: \(error.localizedDescription)")
            errorMessage = "Failed to search users: \(error.localizedDescription)"
            searchResults = []
        }
        
        isSearching = false
    }
    
    func sendFriendRequest(toUserId: UUID) async {
        guard let userId = userId else {
            errorMessage = "User ID not available"
            return
        }
        
        errorMessage = nil
        
        do {
            _ = try await supabaseService.sendFriendRequest(fromUserId: userId, toUserId: toUserId)
            // Reload friends and search results
            await loadFriends()
            // Remove from search results or update status
            if let index = searchResults.firstIndex(where: { $0.userId == toUserId }) {
                var updatedUser = searchResults[index]
                updatedUser.friendshipStatus = "pending"
                searchResults[index] = updatedUser
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func acceptFriendRequest(friendshipId: UUID) async {
        errorMessage = nil
        
        do {
            _ = try await supabaseService.acceptFriendRequest(friendshipId: friendshipId)
            // Reload friends and requests
            await loadFriends()
            await loadFriendRequests()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func removeFriend(friendshipId: UUID) async {
        errorMessage = nil
        
        do {
            try await supabaseService.removeFriend(friendshipId: friendshipId)
            await loadFriends()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

