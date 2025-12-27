//
//  Accountability_BuddyApp.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/8/25.
//


import SwiftUI

@main
struct AccountabilityBuddyApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    // Handle OAuth callback URL
                    // Supabase will automatically process the callback
                    // We just need to refresh the auth status
                    Task {
                        await authViewModel.checkAuthStatus()
                    }
                }
        }
    }
}
