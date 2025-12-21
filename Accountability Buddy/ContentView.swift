//
//  ContentView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/8/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            // Show loading screen while checking auth status
            if authViewModel.isCheckingAuth {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .padding(.top)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if authViewModel.isAuthenticated {
                // Use custom tab bar for iPad to avoid sidebar, standard TabView for iPhone
                if UIDevice.current.userInterfaceIdiom == .pad {
                    // iPad: Custom layout with visible tab bar
                    VStack(spacing: 0) {
                        // Main content area
                        Group {
                            switch selectedTab {
                            case 0:
                                GoalsView()
                                    .environmentObject(authViewModel)
                            case 1:
                                FriendsView()
                                    .environmentObject(authViewModel)
                            case 2:
                                NotificationsView()
                                    .environmentObject(authViewModel)
                            case 3:
                                ProfileView()
                                    .environmentObject(authViewModel)
                            default:
                                GoalsView()
                                    .environmentObject(authViewModel)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Custom tab bar at bottom
                        HStack(spacing: 0) {
                            TabBarButton(
                                icon: "target",
                                label: "Goals",
                                isSelected: selectedTab == 0,
                                action: { selectedTab = 0 }
                            )
                            
                            TabBarButton(
                                icon: "person.2.fill",
                                label: "Friends",
                                isSelected: selectedTab == 1,
                                action: { selectedTab = 1 }
                            )
                            
                            TabBarButton(
                                icon: "bell",
                                label: "Notifications",
                                isSelected: selectedTab == 2,
                                action: { selectedTab = 2 }
                            )
                            
                            TabBarButton(
                                icon: "person.fill",
                                label: "Profile",
                                isSelected: selectedTab == 3,
                                action: { selectedTab = 3 }
                            )
                        }
                        .frame(height: 60)
                        .background(Color(.systemBackground))
                        .overlay(
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundColor(Color(.separator)),
                            alignment: .top
                        )
                    }
                } else {
                    // iPhone: Standard TabView
                    TabView {
                        GoalsView()
                            .tabItem {
                                Label("Goals", systemImage: "target")
                            }
                            .environmentObject(authViewModel)
                        
                        FriendsView()
                            .tabItem {
                                Label("Friends", systemImage: "person.2.fill")
                            }
                            .environmentObject(authViewModel)
                        
                        NotificationsView()
                            .tabItem {
                                Label("Notifications", systemImage: "bell")
                            }
                            .environmentObject(authViewModel)
                        
                        ProfileView()
                            .tabItem {
                                Label("Profile", systemImage: "person.fill")
                            }
                            .environmentObject(authViewModel)
                    }
                }
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            authViewModel.checkAuthStatus()
        }
    }
}

// Custom tab bar button for iPad
struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(isSelected ? .blue : .secondary)
        }
    }
}
