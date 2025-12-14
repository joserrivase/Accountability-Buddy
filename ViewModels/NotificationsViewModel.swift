//
//  NotificationsViewModel.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import Foundation
import SwiftUI

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    private var userId: UUID?
    private var previousNotificationIds: Set<UUID> = [] // Track which notifications we've already shown
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    func setUserId(_ userId: UUID) {
        self.userId = userId
        Task {
            await loadNotifications()
        }
    }
    
    func loadNotifications() async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedNotifications = try await supabaseService.fetchNotifications(userId: userId)
            
            // Check for new unread notifications that we haven't shown yet
            // Only trigger for notifications created in the last 10 minutes to avoid triggering old notifications on app launch
            let tenMinutesAgo = Date().addingTimeInterval(-600)
            let newUnreadNotifications = fetchedNotifications.filter { notification in
                !notification.isRead 
                && !previousNotificationIds.contains(notification.id)
                && notification.createdAt > tenMinutesAgo
            }
            
            // Trigger local notifications for new unread notifications
            for notification in newUnreadNotifications {
                triggerLocalNotification(for: notification)
            }
            
            // Update tracked notification IDs (only track unread ones to avoid memory issues)
            previousNotificationIds = Set(fetchedNotifications.filter { !$0.isRead }.map { $0.id })
            
            notifications = fetchedNotifications
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Trigger a local notification based on the notification type
    private func triggerLocalNotification(for notification: AppNotification) {
        // Check authorization first
        Task {
            let status = await NotificationService.shared.checkAuthorizationStatus()
            guard status == .authorized else {
                return // Not authorized, don't send notification
            }
            
            // Send appropriate local notification based on type
            switch notification.type {
            case .goalUpdate:
                // Check if it's a goal completion or progress update
                if notification.message.contains("has been completed") {
                    // Goal completed notification
                    let goalName = extractGoalName(from: notification.message) ?? "your goal"
                    NotificationService.shared.notifyGoalCompleted(goalName: goalName)
                } else {
                    // Progress update notification
                    let goalName = extractGoalName(from: notification.message) ?? "your goal"
                    let updaterName = extractUpdaterName(from: notification.message) ?? "Your buddy"
                    NotificationService.shared.notifyBuddyProgressUpdate(
                        goalName: goalName,
                        buddyName: updaterName
                    )
                }
                
            case .friendRequest:
                // Extract sender name from message
                let senderName = extractSenderName(from: notification.message) ?? "Someone"
                NotificationService.shared.notifyFriendRequest(senderName: senderName)
                
            case .friendRequestAccepted:
                // Extract accepter name from message
                let accepterName = extractAccepterName(from: notification.message) ?? "Someone"
                NotificationService.shared.notifyFriendRequestAccepted(accepterName: accepterName)
            }
        }
    }
    
    /// Extract goal name from notification message
    private func extractGoalName(from message: String) -> String? {
        // Message format: "X updated progress on \"Goal Name\"" or "The \"Goal Name\" goal has been completed..."
        if let startRange = message.range(of: "\""),
           let endRange = message.range(of: "\"", range: startRange.upperBound..<message.endIndex) {
            return String(message[startRange.upperBound..<endRange.lowerBound])
        }
        return nil
    }
    
    /// Extract sender name from notification message
    private func extractSenderName(from message: String) -> String? {
        // Message format: "X wants to be your friend"
        if let wantsRange = message.range(of: " wants to be your friend") {
            return String(message[..<wantsRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
    
    /// Extract accepter name from notification message
    private func extractAccepterName(from message: String) -> String? {
        // Message format: "X accepted your friend request"
        if let acceptedRange = message.range(of: " accepted your friend request") {
            return String(message[..<acceptedRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
    
    /// Extract updater name from notification message
    private func extractUpdaterName(from message: String) -> String? {
        // Message format: "X updated progress on \"Goal Name\""
        if let updatedRange = message.range(of: " updated progress on") {
            return String(message[..<updatedRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
    
    func markAsRead(notificationId: UUID) async {
        errorMessage = nil
        
        do {
            _ = try await supabaseService.markNotificationAsRead(notificationId: notificationId)
            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                var updatedNotification = notifications[index]
                updatedNotification.isRead = true
                notifications[index] = updatedNotification
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func markAllAsRead() async {
        guard let userId = userId else { return }
        
        errorMessage = nil
        
        do {
            try await supabaseService.markAllNotificationsAsRead(userId: userId)
            // Update local state
            for index in notifications.indices {
                var updatedNotification = notifications[index]
                updatedNotification.isRead = true
                notifications[index] = updatedNotification
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteNotification(notificationId: UUID) async {
        errorMessage = nil
        
        do {
            try await supabaseService.deleteNotification(notificationId: notificationId)
            notifications.removeAll { $0.id == notificationId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

