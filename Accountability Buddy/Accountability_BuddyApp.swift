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
        }
    }
}
