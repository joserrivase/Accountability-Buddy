//
//  SettingsView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    
    @State private var showingUpdateAccount = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        showingUpdateAccount = true
                    }) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.blue)
                            Text("Update Account")
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await authViewModel.signOut()
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.orange)
                            Text("Logout")
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Account")
                        }
                    }
                    .disabled(isDeleting)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingUpdateAccount) {
                if let userId = authViewModel.currentUserId {
                    EditProfileView(viewModel: profileViewModel)
                        .onAppear {
                            profileViewModel.setUserId(userId)
                        }
                }
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently deleted.")
            }
            .onAppear {
                if let userId = authViewModel.currentUserId {
                    profileViewModel.setUserId(userId)
                }
            }
        }
    }
    
    private func deleteAccount() async {
        guard let userId = authViewModel.currentUserId else { return }
        
        isDeleting = true
        
        do {
            // Delete all user data first
            try await deleteUserData(userId: userId)
            
            // Then delete the account
            try await SupabaseService.shared.deleteAccount(userId: userId)
            
            // Sign out and dismiss
            await authViewModel.signOut()
            dismiss()
        } catch {
            print("Error deleting account: \(error)")
            authViewModel.errorMessage = "Failed to delete account: \(error.localizedDescription)"
        }
        
        isDeleting = false
    }
    
    private func deleteUserData(userId: UUID) async throws {
        // Delete all user's goals (this will cascade delete progress)
        let goals = try await SupabaseService.shared.fetchGoals(userId: userId)
        for goal in goals {
            try? await SupabaseService.shared.deleteGoal(goalId: goal.id)
        }
        
        // Delete all friendships
        let friendships = try await SupabaseService.shared.getUserFriendships(userId: userId)
        for friendship in friendships {
            try? await SupabaseService.shared.removeFriend(friendshipId: friendship.id)
        }
        
        // Delete all notifications
        let notifications = try await SupabaseService.shared.fetchNotifications(userId: userId)
        for notification in notifications {
            try? await SupabaseService.shared.deleteNotification(notificationId: notification.id)
        }
    }
}

