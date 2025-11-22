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
            notifications = try await supabaseService.fetchNotifications(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
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

