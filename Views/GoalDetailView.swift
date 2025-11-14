//
//  GoalDetailView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI

struct GoalDetailView: View {
    @Environment(\.dismiss) var dismiss
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
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Goal Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(goalWithProgress.goal.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(goalWithProgress.goal.trackingMethod.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let buddyId = goalWithProgress.goal.buddyId {
                            Text("With Accountability Buddy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // My Progress Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Progress")
                            .font(.headline)
                        
                        progressView(for: myProgressData, isMine: true)
                        
                        progressInputView(isMine: true)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Buddy Progress Section
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
                .padding()
            }
            .navigationTitle("Goal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                myProgress = myProgressData
                buddyProgress = buddyProgressData
                
                // Initialize input values
                if let progress = myProgressData {
                    switch goalWithProgress.goal.trackingMethod {
                    case .inputNumbers:
                        numericInput = progress.numericValue != nil ? String(Int(progress.numericValue!)) : ""
                    default:
                        break
                    }
                }
            }
            .onChange(of: viewModel.goals) { updatedGoals in
                // Reload progress when goals update
                if let updatedGoal = updatedGoals.first(where: { $0.goal.id == goalWithProgress.goal.id }) {
                    goalWithProgress = updatedGoal
                    myProgress = myProgressData
                    buddyProgress = buddyProgressData
                }
            }
        }
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
                        ForEach(items.prefix(5), id: \.self) { item in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(item)
                                    .font(.caption)
                            }
                        }
                        if items.count > 5 {
                            Text("+ \(items.count - 5) more")
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
                                var items = myProgressData?.listItems ?? []
                                items.append(newListItem)
                                Task {
                                    await viewModel.updateGoalProgress(
                                        goalId: goalWithProgress.goal.id,
                                        listItems: items
                                    )
                                    // Reload goals to get updated progress
                                    await viewModel.loadGoals()
                                }
                                newListItem = ""
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

