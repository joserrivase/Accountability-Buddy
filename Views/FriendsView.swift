//
//  FriendsView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI
import UIKit

struct FriendsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = FriendsViewModel()
    @State private var showingAddFriend = false
    @State private var showingShareSheet = false
    
    // App Store link for sharing
    private let appStoreURL = "https://apps.apple.com/us/app/buddyup-accountability-app/id6756550977"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Friends List
                if viewModel.isLoading && viewModel.friends.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.friends.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No friends yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Tap the + button to add friends")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.friends) { friend in
                            FriendRowView(friend: friend)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                // Invite Friends to App Card
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                        Text("Invite Friends to App")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Invite your friends to join you in your goals")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Text("Send Invite")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheetContainer(activityItems: [appStoreURL])
                    .presentationDetents([.medium])
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .onAppear {
                if let userId = authViewModel.currentUserId {
                    viewModel.setUserId(userId)
                }
            }
            .refreshable {
                await viewModel.loadFriends()
            }
        }
        .navigationViewStyle(.stack) // Force stack style on iPad to avoid sidebar
    }
}

// Friend Row View
struct FriendRowView: View {
    let friend: UserProfile
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let imageUrlString = friend.profileImageUrl,
               let imageUrl = URL(string: imageUrlString) {
                RemoteImageView(url: imageUrl) {
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay(ProgressView())
                }
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            // Friend Info
            VStack(alignment: .leading, spacing: 4) {
                let displayName = friend.displayName
                if displayName != "User" {
                    Text(displayName)
                        .font(.headline)
                } else {
                    Text("No name")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                if let username = friend.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

