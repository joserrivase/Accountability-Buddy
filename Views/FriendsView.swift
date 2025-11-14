//
//  FriendsView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = FriendsViewModel()
    @State private var showingAddFriend = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Friends").tag(0)
                    Text("Requests").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
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
                                FriendRowView(friend: friend) {
                                    if let friendshipId = friend.friendshipId {
                                        Task {
                                            await viewModel.removeFriend(friendshipId: friendshipId)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                } else {
                    // Friend Requests
                    if viewModel.friendRequests.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "envelope")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text("No friend requests")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        Spacer()
                    } else {
                        List {
                            ForEach(viewModel.friendRequests) { request in
                                FriendRequestRowView(request: request) {
                                    if let friendshipId = request.friendshipId {
                                        Task {
                                            await viewModel.acceptFriendRequest(friendshipId: friendshipId)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
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
                await viewModel.loadFriendRequests()
            }
        }
    }
}

// Friend Row View
struct FriendRowView: View {
    let friend: UserProfile
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let imageUrlString = friend.profileImageUrl,
               let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    @unknown default:
                        EmptyView()
                    }
                }
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
                if let name = friend.name, !name.isEmpty {
                    Text(name)
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
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// Friend Request Row View
struct FriendRequestRowView: View {
    let request: UserProfile
    let onAccept: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let imageUrlString = request.profileImageUrl,
               let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    @unknown default:
                        EmptyView()
                    }
                }
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
                if let name = request.name, !name.isEmpty {
                    Text(name)
                        .font(.headline)
                } else {
                    Text("No name")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                if let username = request.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Accept button
            Button(action: onAccept) {
                Text("Accept")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}

