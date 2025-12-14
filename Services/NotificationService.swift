//
//  NotificationService.swift
//  Accountability Buddy
//
//  Created for notification management
//

import Foundation
import UserNotifications

@MainActor
class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    /// Request notification permission from the user
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("❌ Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    /// Check current notification authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    /// Send a local notification
    func sendNotification(
        title: String,
        body: String,
        identifier: String? = nil
    ) {
        let center = UNUserNotificationCenter.current()
        
        // Check authorization first
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("⚠️ Notifications not authorized")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.badge = NSNumber(value: 1)
            
            // Create trigger (immediate)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            
            // Create request
            let requestId = identifier ?? UUID().uuidString
            let request = UNNotificationRequest(
                identifier: requestId,
                content: content,
                trigger: trigger
            )
            
            // Schedule notification
            center.add(request) { error in
                if let error = error {
                    print("❌ Error scheduling notification: \(error)")
                } else {
                    print("✅ Notification scheduled: \(title)")
                }
            }
        }
    }
    
    /// Send notification when buddy updates progress
    func notifyBuddyProgressUpdate(goalName: String, buddyName: String) {
        sendNotification(
            title: "Goal Update",
            body: "\(buddyName) updated progress on \"\(goalName)\"",
            identifier: "buddy-progress-\(UUID().uuidString)"
        )
    }
    
    /// Send notification when friend request is received
    func notifyFriendRequest(senderName: String) {
        sendNotification(
            title: "New Friend Request",
            body: "\(senderName) wants to be your friend",
            identifier: "friend-request-\(UUID().uuidString)"
        )
    }
    
    /// Send notification when friend request is accepted
    func notifyFriendRequestAccepted(accepterName: String) {
        sendNotification(
            title: "Friend Request Accepted",
            body: "\(accepterName) accepted your friend request",
            identifier: "friend-accepted-\(UUID().uuidString)"
        )
    }
    
    /// Send notification when goal is completed (winner determined)
    func notifyGoalCompleted(goalName: String) {
        sendNotification(
            title: "Goal Completed",
            body: "The \"\(goalName)\" goal has been completed. Check it to see the results!",
            identifier: "goal-completed-\(UUID().uuidString)"
        )
    }
}

