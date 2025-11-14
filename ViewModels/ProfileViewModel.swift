//
//  ProfileViewModel.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaving = false
    
    private let supabaseService = SupabaseService.shared
    private var userId: UUID?
    
    func setUserId(_ userId: UUID) {
        self.userId = userId
        Task {
            await loadProfile()
        }
    }
    
    func loadProfile() async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            profile = try await supabaseService.fetchProfile(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateProfile(username: String?, name: String?, profileImageUrl: String?) async {
        guard let userId = userId else {
            errorMessage = "User ID not available"
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            profile = try await supabaseService.updateProfile(
                userId: userId,
                username: username,
                name: name,
                profileImageUrl: profileImageUrl
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
    
    func uploadProfileImage(imageData: Data) async -> String? {
        guard let userId = userId else {
            errorMessage = "User ID not available"
            return nil
        }
        
        do {
            let imageUrl = try await supabaseService.uploadProfileImage(userId: userId, imageData: imageData)
            return imageUrl
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

