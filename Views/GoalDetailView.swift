//
//  GoalDetailView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI

struct GoalDetailView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: GoalsViewModel
    @State var goalWithProgress: GoalWithProgress
    
    @State private var myProgress: GoalProgress?
    @State private var buddyProgress: GoalProgress?
    @State private var numericInput: String = ""
    @State private var newListItem: String = ""
    
    var isCreator: Bool {
        guard let currentUserId = authViewModel.currentUserId else { return false }
        return goalWithProgress.goal.creatorId == currentUserId
    }
    
    var myProgressData: GoalProgress? {
        guard let currentUserId = authViewModel.currentUserId else { return nil }
        if isCreator {
            return goalWithProgress.creatorProgress
        } else {
            return goalWithProgress.buddyProgress
        }
    }
    
    var buddyProgressData: GoalProgress? {
        guard let currentUserId = authViewModel.currentUserId else { return nil }
        if isCreator {
            return goalWithProgress.buddyProgress
        } else {
            return goalWithProgress.creatorProgress
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                goalHeader
                
                if goalWithProgress.goal.trackingMethod == .inputList {
                    inputListDetailContent
                } else {
                    defaultDetailContent
                }
            }
            .padding()
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            myProgress = myProgressData
            buddyProgress = buddyProgressData
            
            if let progress = myProgressData, goalWithProgress.goal.trackingMethod == .inputNumbers {
                numericInput = progress.numericValue != nil ? String(Int(progress.numericValue!)) : ""
            }
        }
        .onChange(of: viewModel.goals) { updatedGoals in
            if let updatedGoal = updatedGoals.first(where: { $0.goal.id == goalWithProgress.goal.id }) {
                // Only update if the goal actually changed (don't overwrite optimistic updates)
                goalWithProgress = updatedGoal
                // Update local progress states
                if myProgress == nil || myProgress?.listItems?.count != updatedGoal.creatorProgress?.listItems?.count {
                    myProgress = myProgressData
                }
                if buddyProgress == nil || buddyProgress?.listItems?.count != updatedGoal.buddyProgress?.listItems?.count {
                    buddyProgress = buddyProgressData
                }
            }
        }
    }
    
    private var goalHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(goalWithProgress.goal.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text(goalWithProgress.goal.trackingMethod.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if goalWithProgress.goal.buddyId != nil {
                Text("With Accountability Buddy")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var defaultDetailContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("My Progress")
                    .font(.headline)
                
                progressView(for: myProgressData, isMine: true)
                progressInputView(isMine: true)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            if goalWithProgress.goal.buddyId != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Buddy's Progress")
                        .font(.headline)
                    
                    progressView(for: buddyProgressData, isMine: false)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private var inputListDetailContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            listComparisonView
            progressInputView(isMine: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var listComparisonView: some View {
        HStack(alignment: .top, spacing: 16) {
            // Use myProgress state for immediate updates, fallback to goalWithProgress
            let myItems = myProgress?.listItems ?? myProgressData?.listItems ?? []
            userListColumn(title: "Me", items: myItems)
            
            if goalWithProgress.goal.buddyId != nil {
                // Use buddyProgress state for immediate updates, fallback to goalWithProgress
                let buddyItems = buddyProgress?.listItems ?? buddyProgressData?.listItems ?? []
                userListColumn(title: "Buddy", items: buddyItems)
            }
        }
    }
    
    private func userListColumn(title: String, items: [GoalListItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            if items.isEmpty {
                Text("No entries yet")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(items.sorted(by: { $0.date > $1.date }).prefix(10)) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.subheadline)
                        Text(formatDate(item.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func progressView(for progress: GoalProgress?, isMine: Bool) -> some View {
        if let progress = progress {
            switch goalWithProgress.goal.trackingMethod {
            case .inputNumbers:
                if let value = progress.numericValue {
                    Text("\(Int(value))")
                        .font(.title)
                        .fontWeight(.bold)
                } else {
                    Text("No progress yet")
                        .foregroundColor(.secondary)
                }
                
            case .trackDaysCompleted:
                if let days = progress.completedDays {
                    Text("\(days.count) days completed")
                        .font(.title2)
                    if !days.isEmpty {
                        Text("Last: \(formatDate(days.last ?? ""))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No days completed yet")
                        .foregroundColor(.secondary)
                }
                
            case .inputList:
                if let items = progress.listItems, !items.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(items.count) items completed")
                            .font(.title2)
                        if let latest = items.sorted(by: { $0.date > $1.date }).first {
                            Text("Latest: \(latest.title) on \(formatDate(latest.date))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("No items completed yet")
                        .foregroundColor(.secondary)
                }
            }
        } else {
            Text("No progress yet")
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func progressInputView(isMine: Bool) -> some View {
        if !isMine {
            EmptyView()
        } else {
            switch goalWithProgress.goal.trackingMethod {
            case .inputNumbers:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Update Progress")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    HStack {
                        TextField("Enter number", text: $numericInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Update") {
                            if let value = Double(numericInput) {
                                Task {
                                    await viewModel.updateGoalProgress(
                                        goalId: goalWithProgress.goal.id,
                                        numericValue: value
                                    )
                                    // Reload goals to get updated progress
                                    await viewModel.loadGoals()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.top, 8)
                
            case .trackDaysCompleted:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mark Today as Completed")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Button("Mark Today Complete") {
                        let today = formatDate(Date())
                        var days = myProgressData?.completedDays ?? []
                        if !days.contains(today) {
                            days.append(today)
                            Task {
                                await viewModel.updateGoalProgress(
                                    goalId: goalWithProgress.goal.id,
                                    completedDays: days
                                )
                                // Reload goals to get updated progress
                                await viewModel.loadGoals()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 8)
                
            case .inputList:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Completed Item")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    HStack {
                        TextField("Enter item", text: $newListItem)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Add") {
                            if !newListItem.isEmpty {
                                let newEntry = GoalListItem(title: newListItem, date: Date())
                                let itemToAdd = newListItem
                                // Clear input immediately
                                newListItem = ""
                                
                                // Optimistic update - update local state immediately for instant UI feedback
                                var currentItems = myProgress?.listItems ?? myProgressData?.listItems ?? []
                                currentItems.append(newEntry)
                                
                                // Update myProgress state immediately
                                if var existingProgress = myProgress {
                                    existingProgress.listItems = currentItems
                                    myProgress = existingProgress
                                } else if var existingProgress = myProgressData {
                                    existingProgress.listItems = currentItems
                                    myProgress = existingProgress
                                } else {
                                    // Create new progress
                                    let currentUserId = isCreator ? goalWithProgress.goal.creatorId : (goalWithProgress.goal.buddyId ?? UUID())
                                    myProgress = GoalProgress(
                                        id: UUID(),
                                        goalId: goalWithProgress.goal.id,
                                        userId: currentUserId,
                                        listItems: currentItems
                                    )
                                }
                                
                                // Update goalWithProgress for immediate UI update
                                if isCreator {
                                    if var creatorProgress = goalWithProgress.creatorProgress {
                                        creatorProgress.listItems = currentItems
                                        goalWithProgress.creatorProgress = creatorProgress
                                    } else {
                                        goalWithProgress.creatorProgress = GoalProgress(
                                            id: UUID(),
                                            goalId: goalWithProgress.goal.id,
                                            userId: goalWithProgress.goal.creatorId,
                                            listItems: currentItems
                                        )
                                    }
                                } else {
                                    if var buddyProgress = goalWithProgress.buddyProgress {
                                        buddyProgress.listItems = currentItems
                                        goalWithProgress.buddyProgress = buddyProgress
                                    } else if let buddyId = goalWithProgress.goal.buddyId {
                                        goalWithProgress.buddyProgress = GoalProgress(
                                            id: UUID(),
                                            goalId: goalWithProgress.goal.id,
                                            userId: buddyId,
                                            listItems: currentItems
                                        )
                                    }
                                }
                                
                                // Then sync with server in background
                                Task {
                                    await viewModel.updateGoalProgress(
                                        goalId: goalWithProgress.goal.id,
                                        listItems: currentItems
                                    )
                                    // Reload to ensure sync and get any updates from buddy
                                    await viewModel.loadGoals()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newListItem.isEmpty)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return dateString
    }
    
}


