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
    
    var body: some View {
        NavigationView {
            VStack {
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
            }
        }
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
        }
        .padding(.vertical, 4)
    }
}

