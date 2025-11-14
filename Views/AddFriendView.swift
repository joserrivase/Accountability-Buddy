//
//  AddFriendView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: FriendsViewModel
    @State private var searchQuery = ""
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search by username or name", text: $searchQuery)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: searchQuery) { newValue in
                            // Cancel previous search task
                            searchTask?.cancel()
                            
                            // Clear results immediately if query is empty
                            if newValue.isEmpty {
                                viewModel.searchResults = []
                                viewModel.isSearching = false
                                return
                            }
                            
                            // Debounce search
                            searchTask = Task {
                                do {
                                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                    // Check if task was cancelled before proceeding
                                    try Task.checkCancellation()
                                    await viewModel.searchUsers(query: newValue)
                                } catch is CancellationError {
                                    // Task was cancelled, ignore
                                    return
                                } catch {
                                    // Other errors are handled in viewModel
                                    print("Search task error: \(error)")
                                }
                            }
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Search Results
                if viewModel.isSearching {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Search for friends")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Enter a username or name to search")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else if viewModel.searchResults.isEmpty && searchQuery.count >= 2 {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No users found")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Try a different search term or make sure users have set their username or name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    Spacer()
                } else if searchQuery.count > 0 && searchQuery.count < 2 {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("Enter at least 2 characters to search")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.searchResults) { user in
                            SearchResultRowView(user: user) {
                                Task {
                                    await viewModel.sendFriendRequest(toUserId: user.userId)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil && !viewModel.errorMessage!.isEmpty)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                }
            }
            .onAppear {
                // Clear any previous errors when view appears
                viewModel.errorMessage = nil
                viewModel.searchResults = []
            }
        }
    }
}

// Search Result Row View
struct SearchResultRowView: View {
    let user: UserProfile
    let onAddFriend: () -> Void
    
    var friendshipStatus: String? {
        user.friendshipStatus
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let imageUrlString = user.profileImageUrl,
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
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                if let name = user.name, !name.isEmpty {
                    Text(name)
                        .font(.headline)
                } else {
                    Text("No name")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                if let username = user.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action Button
            if let status = friendshipStatus {
                if status == "accepted" {
                    Text("Friends")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                } else if status == "pending" {
                    Text("Pending")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
            } else {
                Button(action: onAddFriend) {
                    Text("Add")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

