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
    
    var body: some View {
        NavigationView {
            VStack {
                // Goals List
                if viewModel.isLoading && viewModel.goals.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.goals.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "target")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No goals yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Tap the + button to create your first goal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.goals) { goalWithProgress in
                            NavigationLink(destination: GoalDetailView(viewModel: viewModel, goalWithProgress: goalWithProgress).environmentObject(authViewModel)) {
                                GoalRowView(goalWithProgress: goalWithProgress)
                            }
                        }
                        .onDelete(perform: { indexSet in
                            for index in indexSet {
                                Task {
                                    await viewModel.deleteGoal(goalId: viewModel.goals[index].goal.id)
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

