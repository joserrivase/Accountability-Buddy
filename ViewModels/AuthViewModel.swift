//
//  AuthViewModel.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/8/25.
//

import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserId: UUID?
    @Published var isLoading = false
    @Published var isCheckingAuth = true  // Track if we're still checking auth status
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        isCheckingAuth = true  // Set to true when starting check
        Task {
            if let userId = await supabaseService.getCurrentUser() {
                currentUserId = userId
                isAuthenticated = true
            } else {
                isAuthenticated = false
                currentUserId = nil
            }
            isCheckingAuth = false  // Set to false when check completes
        }
    }
    
    private func checkAuthStatusAsync() async {
        isCheckingAuth = true  // Set to true when starting check
        if let userId = await supabaseService.getCurrentUser() {
            currentUserId = userId
            isAuthenticated = true
        } else {
            isAuthenticated = false
            currentUserId = nil
        }
        isCheckingAuth = false  // Set to false when check completes
    }
    
    func signUp(email: String, password: String, username: String, firstName: String, lastName: String) async {
        isLoading = true
        errorMessage = nil
        
        // First, check if username is available
        let isAvailable = await supabaseService.checkUsernameAvailability(username: username)
        guard isAvailable else {
            errorMessage = "This username is already taken. Please choose a different username."
            isLoading = false
            return
        }
        
        do {
            try await supabaseService.signUp(email: email, password: password, username: username, firstName: firstName, lastName: lastName)
            // Check if user is authenticated (has session) or needs email confirmation
            await checkAuthStatusAsync()
            
            // If not authenticated after signup, it likely means email confirmation is needed
            if !isAuthenticated {
                errorMessage = "Account created! Please check your email to confirm your account before signing in."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.signIn(email: email, password: password)
            await checkAuthStatusAsync()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.signOut()
            isAuthenticated = false
            currentUserId = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.resetPassword(email: email)
            errorMessage = "Password reset email sent! Please check your inbox and follow the instructions to reset your password."
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
