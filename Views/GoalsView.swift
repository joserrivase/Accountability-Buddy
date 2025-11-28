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
    
    enum GoalViewType: String, CaseIterable {
        case active = "Active"
        case finished = "Finished"
    }
    
    private var filteredGoals: [GoalWithProgress] {
        switch selectedView {
        case .active:
            // For now, show all goals as active (will be updated later when finished criteria is defined)
            return viewModel.goals
        case .finished:
            // For now, show empty list (will be updated later when finished criteria is defined)
            return []
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
                                GoalRowView(goalWithProgress: goalWithProgress)
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
            }
            .refreshable {
                await viewModel.loadGoals()
            }
        }
    }
}

// Goal Row View
struct GoalRowView: View {
    let goalWithProgress: GoalWithProgress
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "target")
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goalWithProgress.goal.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(goalWithProgress.goal.trackingMethod.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if goalWithProgress.goal.buddyId != nil {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("With Buddy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

