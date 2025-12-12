//
//  ProfileView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var goalsViewModel = GoalsViewModel()
    @StateObject private var friendsViewModel = FriendsViewModel()
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingMailComposer = false
    @State private var userEmail: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.isLoading && viewModel.profile == nil {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    // Profile Image - Smaller
                    if let imageUrlString = viewModel.profile?.profileImageUrl,
                       let imageUrl = URL(string: imageUrlString) {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 80, height: 80)
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
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                    }
                    
                    // User Info
                    VStack(spacing: 8) {
                        if let name = viewModel.profile?.name, !name.isEmpty {
                            Text(name)
                                .font(.title2)
                                .fontWeight(.bold)
                        } else {
                            Text("No name set")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                        
                        if let username = viewModel.profile?.username, !username.isEmpty {
                            Text("@\(username)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No username set")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top)
                    
                    // Stats Row
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text("\(goalsViewModel.goals.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Goals")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(friendsViewModel.friends.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Friends")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Provide Feedback Button
                    Button(action: {
                        Task {
                            // Get user email before showing form
                            let email = await SupabaseService.shared.getCurrentUserEmail()
                            await MainActor.run {
                                userEmail = email
                                showingMailComposer = true
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Provide Feedback")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(authViewModel: authViewModel)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showingMailComposer) {
                let userName = viewModel.profile?.name ?? viewModel.profile?.username
                let email = userEmail
                
                FeedbackFormView(
                    isPresented: $showingMailComposer,
                    preFilledName: userName,
                    preFilledEmail: email
                )
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
                    goalsViewModel.setUserId(userId)
                    friendsViewModel.setUserId(userId)
                }
            }
        }
    }
}

