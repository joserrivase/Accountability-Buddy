//
//  GoalsView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = GoalsViewModel()
    @StateObject private var friendsViewModel = FriendsViewModel()
    @State private var showingAddGoal = false
    @State private var selectedView: GoalViewType = .active
    @State private var profileNameCache: [UUID: String] = [:] // Cache for profile names
    
    enum GoalViewType: String, CaseIterable {
        case active = "Active"
        case finished = "Finished"
    }
    
    private var filteredGoals: [GoalWithProgress] {
        guard let currentUserId = authViewModel.currentUserId else { return [] }
        
        switch selectedView {
        case .active:
            // Show goals that are:
            // 1. Not finished (goalStatus != .finished)
            // 2. Or pending_finish but current user hasn't seen the message yet
            return viewModel.goals.filter { goalWithProgress in
                // If goal is finished, don't show in active
                if goalWithProgress.goal.goalStatus == .finished {
                    return false
                }
                
                // If goal is pending_finish, check if current user has seen the message
                if goalWithProgress.goal.goalStatus == .pendingFinish {
                    // Get current user's progress
                    let myProgress = goalWithProgress.goal.creatorId == currentUserId 
                        ? goalWithProgress.creatorProgress 
                        : goalWithProgress.buddyProgress
                    
                    // Only show in active if user hasn't seen the message
                    return myProgress?.hasSeenWinnerMessage != true
                }
                
                // For all other statuses (active, nil), show in active
                return true
            }
        case .finished:
            // Show goals that are:
            // 1. Fully finished (goalStatus == .finished)
            // 2. Or pending_finish AND current user has seen the message
            return viewModel.goals.filter { goalWithProgress in
                // If goal is fully finished, show it
                if goalWithProgress.goal.goalStatus == .finished {
                    return true
                }
                
                // If goal is pending_finish, check if current user has seen the message
                if goalWithProgress.goal.goalStatus == .pendingFinish {
                    // Get current user's progress
                    let myProgress = goalWithProgress.goal.creatorId == currentUserId 
                        ? goalWithProgress.creatorProgress 
                        : goalWithProgress.buddyProgress
                    
                    // Show in finished if user has seen the message
                    return myProgress?.hasSeenWinnerMessage == true
                }
                
                // All other statuses don't go in finished
                return false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Toggle between Active and Finished
                Picker("Goal View", selection: $selectedView) {
                    ForEach(GoalViewType.allCases, id: \.self) { viewType in
                        Text(viewType.rawValue).tag(viewType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Goals List
                if viewModel.isLoading && filteredGoals.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredGoals.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: selectedView == .active ? "target" : "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text(selectedView == .active ? "No goals yet" : "No finished goals")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text(selectedView == .active ? "Tap the + button to create your first goal" : "Goals you've completed will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(filteredGoals) { goalWithProgress in
                            NavigationLink(destination: GoalDetailView(viewModel: viewModel, goalWithProgress: goalWithProgress).environmentObject(authViewModel)) {
                                GoalRowView(
                                    goalWithProgress: goalWithProgress,
                                    profileNameCache: profileNameCache
                                )
                                .environmentObject(authViewModel)
                            }
                        }
                        .onDelete(perform: { indexSet in
                            for index in indexSet {
                                Task {
                                    await viewModel.deleteGoal(goalId: filteredGoals[index].goal.id)
                                }
                            }
                        })
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddGoal = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                GoalQuestionnaireView(
                    goalsViewModel: viewModel,
                    friendsViewModel: friendsViewModel
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
                    friendsViewModel.setUserId(userId)
                }
                // Preload all profile names when view appears
                Task {
                    await preloadProfileNames()
                }
            }
            .onChange(of: viewModel.goals) { _ in
                // Reload profile names when goals change
                Task {
                    await preloadProfileNames()
                }
            }
            .refreshable {
                await viewModel.loadGoals()
                await preloadProfileNames()
            }
        }
        .navigationViewStyle(.stack) // Force stack style on iPad to avoid sidebar
    }
    
    /// Preload all profile names for goals to display them immediately
    private func preloadProfileNames() async {
        var cache: [UUID: String] = [:]
        let supabaseService = SupabaseService.shared
        
        // Collect all unique user IDs from goals
        var userIdsToLoad: Set<UUID> = []
        for goalWithProgress in viewModel.goals {
            userIdsToLoad.insert(goalWithProgress.goal.creatorId)
            if let buddyId = goalWithProgress.goal.buddyId {
                userIdsToLoad.insert(buddyId)
            }
        }
        
        // Load all profiles in parallel
        await withTaskGroup(of: (UUID, String?).self) { group in
            for userId in userIdsToLoad {
                group.addTask {
                    if let profile = try? await supabaseService.fetchProfile(userId: userId) {
                        let name = profile.name ?? profile.username ?? "Buddy"
                        return (userId, name)
                    }
                    return (userId, nil)
                }
            }
            
            for await (userId, name) in group {
                if let name = name {
                    cache[userId] = name
                }
            }
        }
        
        profileNameCache = cache
    }
}

// Goal Row View
struct GoalRowView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let goalWithProgress: GoalWithProgress
    let profileNameCache: [UUID: String]
    
    private var otherPersonName: String? {
        guard let currentUserId = authViewModel.currentUserId else { return nil }
        
        let otherPersonId: UUID?
        if goalWithProgress.goal.creatorId == currentUserId {
            otherPersonId = goalWithProgress.goal.buddyId
        } else {
            otherPersonId = goalWithProgress.goal.creatorId
        }
        
        guard let otherPersonId = otherPersonId else { return nil }
        return profileNameCache[otherPersonId]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "target")
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goalWithProgress.goal.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let name = otherPersonName {
                    Text("With \(name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

