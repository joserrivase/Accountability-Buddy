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
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        Task {
            if let userId = await supabaseService.getCurrentUser() {
                currentUserId = userId
                isAuthenticated = true
            } else {
                isAuthenticated = false
                currentUserId = nil
            }
        }
    }
    
    private func checkAuthStatusAsync() async {
        if let userId = await supabaseService.getCurrentUser() {
            currentUserId = userId
            isAuthenticated = true
        } else {
            isAuthenticated = false
            currentUserId = nil
        }
    }
    
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.signUp(email: email, password: password)
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
}
