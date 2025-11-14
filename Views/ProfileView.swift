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
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.isLoading && viewModel.profile == nil {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    // Profile Image
                    if let imageUrlString = viewModel.profile?.profileImageUrl,
                       let imageUrl = URL(string: imageUrlString) {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 120, height: 120)
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
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                            .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                    }
                    
                    // User Info
                    VStack(spacing: 8) {
                        if let name = viewModel.profile?.name, !name.isEmpty {
                            Text(name)
                                .font(.title)
                                .fontWeight(.bold)
                        } else {
                            Text("No name set")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                        
                        if let username = viewModel.profile?.username, !username.isEmpty {
                            Text("@\(username)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No username set")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let email = getCurrentUserEmail() {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    // Edit Profile Button
                    Button(action: {
                        showingEditProfile = true
                    }) {
                        Text("Update Profile")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Sign Out Button
                    Button(action: {
                        Task {
                            await authViewModel.signOut()
                        }
                    }) {
                        Text("Sign Out")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(viewModel: viewModel)
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
        }
    }
    
    private func getCurrentUserEmail() -> String? {
        // Note: We'd need to extend AuthViewModel or SupabaseService to get email
        // For now, return nil or implement email retrieval
        return nil
    }
}

