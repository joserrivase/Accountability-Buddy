//
//  NotificationsView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = NotificationsViewModel()
    @StateObject private var friendsViewModel = FriendsViewModel()
    
    private func handleAcceptFriendRequest(notification: AppNotification) {
        guard notification.type == .friendRequest,
              let fromUserId = notification.relatedUserId else {
            print("❌ ERROR: Invalid notification or missing fromUserId")
            return
        }
        
        Task {
            do {
                // Try to find the friendship using the service method first
                guard let currentUserId = authViewModel.currentUserId else {
                    print("❌ ERROR: No current user ID")
                    return
                }
                
                print("🔍 DEBUG: Looking for pending friendship between \(fromUserId) and \(currentUserId)")
                
                // Try to find the pending friendship directly
                if let friendship = try await SupabaseService.shared.findPendingFriendship(userId1: fromUserId, userId2: currentUserId) {
                    print("✅ DEBUG: Found pending friendship with ID: \(friendship.id)")
                    
                    // Accept the friend request
                    await friendsViewModel.acceptFriendRequest(friendshipId: friendship.id)
                    
                    // Verify it was accepted by reloading friends
                    await friendsViewModel.loadFriends()
                    
                    // Mark notification as read after accepting
                    await viewModel.markAsRead(notificationId: notification.id)
                    
                    // Reload notifications to refresh the list
                    await viewModel.loadNotifications()
                    
                    print("✅ DEBUG: Friend request accepted successfully")
                } else {
                    // Fallback: Load friend requests and try to find it
                    print("⚠️ DEBUG: Friendship not found directly, trying to load friend requests")
                    await friendsViewModel.loadFriendRequests()
                    
                    if let request = friendsViewModel.friendRequests.first(where: { $0.userId == fromUserId }),
                       let friendshipId = request.friendshipId {
                        print("✅ DEBUG: Found friend request in list with ID: \(friendshipId)")
                        
                        await friendsViewModel.acceptFriendRequest(friendshipId: friendshipId)
                        await friendsViewModel.loadFriends()
                        await viewModel.markAsRead(notificationId: notification.id)
                        await viewModel.loadNotifications()
                        
                        print("✅ DEBUG: Friend request accepted via fallback method")
                    } else {
                        print("❌ ERROR: Could not find friend request for user \(fromUserId)")
                        viewModel.errorMessage = "Could not find friend request. Please try refreshing."
                    }
                }
            } catch {
                print("❌ ERROR: Error accepting friend request: \(error)")
                viewModel.errorMessage = "Failed to accept friend request: \(error.localizedDescription)"
            }
        }
    }
    
    private func findAndAcceptFriendship(fromUserId: UUID, notificationId: UUID) async {
        do {
            guard let currentUserId = authViewModel.currentUserId else { return }
            
            // Use the service method to find pending friendship
            if let friendship = try await SupabaseService.shared.findPendingFriendship(userId1: fromUserId, userId2: currentUserId) {
                await friendsViewModel.acceptFriendRequest(friendshipId: friendship.id)
                await friendsViewModel.loadFriends()
                await viewModel.markAsRead(notificationId: notificationId)
                await viewModel.loadNotifications()
            }
        } catch {
            print("Error finding friendship: \(error)")
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.notifications.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "bell")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No notifications")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            NotificationRowView(
                                notification: notification,
                                onAccept: {
                                    handleAcceptFriendRequest(notification: notification)
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteNotification(notificationId: notification.id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.unreadCount > 0 {
                        Button("Mark All Read") {
                            Task {
                                await viewModel.markAllAsRead()
                            }
                        }
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .onAppear {
                if let userId = authViewModel.currentUserId {
                    viewModel.setUserId(userId)
                    friendsViewModel.setUserId(userId)
                }
            }
            .refreshable {
                await viewModel.loadNotifications()
            }
        }
    }
    
}

struct NotificationRowView: View {
    let notification: AppNotification
    let onAccept: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon based on type
            Image(systemName: notification.type == .friendRequest ? "person.badge.plus" : "target")
                .foregroundColor(notification.type == .friendRequest ? .blue : .green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Text(formatDate(notification.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
            
            if notification.type == .friendRequest && !notification.isRead {
                Button(action: {
                    onAccept()
                }) {
                    Text("Accept")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
        }
        .padding(.vertical, 8)
        .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today at \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday at \(formatter.string(from: date))"
        } else if calendar.dateInterval(of: .weekOfYear, for: Date())?.contains(date) ?? false {
            formatter.dateFormat = "EEEE 'at' h:mm a"
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

