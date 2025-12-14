//
//  EditGoalView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI

struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GoalsViewModel
    let goal: Goal
    let onSave: ((Goal) -> Void)?
    
    @State private var editedAnswers: GoalQuestionnaireAnswers
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var buddyName: String? = nil
    
    init(goal: Goal, viewModel: GoalsViewModel, onSave: ((Goal) -> Void)? = nil) {
        self.goal = goal
        self.viewModel = viewModel
        self.onSave = onSave
        
        // Initialize editedAnswers from the goal
        var answers = GoalQuestionnaireAnswers()
        answers.goalName = goal.name
        answers.goalType = goal.goalType
        answers.buddyId = goal.buddyId
        answers.isSolo = goal.buddyId == nil
        answers.taskBeingTracked = goal.taskBeingTracked
        answers.listItems = goal.listItems
        answers.keepStreak = goal.keepStreak
        answers.trackDailyQuantity = goal.trackDailyQuantity
        answers.unitTracked = goal.unitTracked
        answers.challengeOrFriendly = goal.challengeOrFriendly
        answers.winningCondition = goal.winningCondition
        answers.winningNumber = goal.winningNumber
        answers.endDate = goal.endDate
        answers.winnersPrize = goal.winnersPrize
        
        _editedAnswers = State(initialValue: answers)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section(header: Text("Basic Information")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Goal Name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("Enter goal name", text: Binding(
                            get: { editedAnswers.goalName ?? "" },
                            set: { editedAnswers.goalName = $0.isEmpty ? nil : $0 }
                        ))
                    }
                    
                    // Goal Type - Read Only
                    HStack {
                        Text("Goal Type")
                        Spacer()
                        Text(getGoalTypeDisplayName())
                            .foregroundColor(.secondary)
                    }
                    
                    // Accountability Buddy
                    HStack {
                        Text("Accountability Buddy")
                        Spacer()
                        if let buddyId = goal.buddyId {
                            if let name = buddyName {
                                Text(name)
                                    .foregroundColor(.secondary)
                            } else {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        } else {
                            Text("Solo Goal")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Goal-Specific Fields
                if let task = editedAnswers.taskBeingTracked {
                    Section(header: Text("Task Details")) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Task Being Tracked")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField("Enter task name", text: Binding(
                                get: { task },
                                set: { editedAnswers.taskBeingTracked = $0.isEmpty ? nil : $0 }
                            ))
                        }
                    }
                }
                
                if let items = editedAnswers.listItems, !items.isEmpty {
                    Section(header: Text("List Items")) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Item \(index + 1)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextField("Enter item", text: Binding(
                                    get: { item },
                                    set: { newValue in
                                        var updatedItems = items
                                        if newValue.isEmpty {
                                            updatedItems.remove(at: index)
                                        } else {
                                            updatedItems[index] = newValue
                                        }
                                        editedAnswers.listItems = updatedItems.isEmpty ? nil : updatedItems
                                    }
                                ))
                            }
                        }
                        .onDelete { indexSet in
                            var updatedItems = items
                            for index in indexSet.sorted(by: >) {
                                updatedItems.remove(at: index)
                            }
                            editedAnswers.listItems = updatedItems.isEmpty ? nil : updatedItems
                        }
                        
                        Button("Add Item") {
                            var updatedItems = items
                            updatedItems.append("")
                            editedAnswers.listItems = updatedItems
                        }
                    }
                }
                
                // Daily Tracker Options
                if goal.goalType == "daily_tracker" {
                    Section(header: Text("Daily Tracker Options")) {
                        if let keepStreak = editedAnswers.keepStreak {
                            Toggle("Keep Streak", isOn: Binding(
                                get: { keepStreak },
                                set: { editedAnswers.keepStreak = $0 }
                            ))
                        }
                        
                        if let trackQuantity = editedAnswers.trackDailyQuantity {
                            Toggle("Track Daily Quantity", isOn: Binding(
                                get: { trackQuantity },
                                set: { editedAnswers.trackDailyQuantity = $0 }
                            ))
                            
                            if trackQuantity, let unit = editedAnswers.unitTracked {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Unit Tracked")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    TextField("e.g., miles, pages, hours", text: Binding(
                                        get: { unit },
                                        set: { editedAnswers.unitTracked = $0.isEmpty ? nil : $0 }
                                    ))
                                }
                            }
                        }
                    }
                }
                
                // Challenge Settings
                Section(header: Text("Challenge Settings")) {
                    if let mode = editedAnswers.challengeOrFriendly {
                        Picker("Mode", selection: Binding(
                            get: { mode },
                            set: { editedAnswers.challengeOrFriendly = $0 }
                        )) {
                            Text("Friendly").tag("friendly")
                            Text("Challenge").tag("challenge")
                        }
                    }
                    
                    if editedAnswers.isChallenge {
                        // Challenge Objective Dropdown
                        if let currentCondition = editedAnswers.winningCondition {
                            Picker("Challenge Objective", selection: Binding(
                                get: { currentCondition },
                                set: { editedAnswers.winningCondition = $0.isEmpty ? nil : $0 }
                            )) {
                                ForEach(getWinningConditionOptions(), id: \.id) { option in
                                    Text(option.title).tag(option.id)
                                }
                            }
                        }
                        
                        if let winningNumber = editedAnswers.winningNumber {
                            HStack {
                                Text("Target Number")
                                    .frame(width: 120, alignment: .leading)
                                Stepper(value: Binding(
                                    get: { winningNumber },
                                    set: { editedAnswers.winningNumber = $0 }
                                ), in: 1...10000) {
                                    Text("\(winningNumber)")
                                }
                            }
                        }
                        
                        if let endDate = editedAnswers.endDate {
                            DatePicker("End Date", selection: Binding(
                                get: { endDate },
                                set: { editedAnswers.endDate = $0 }
                            ), displayedComponents: .date)
                        }
                        
                        if let prize = editedAnswers.winnersPrize {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Challenge Stakes")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextField("e.g., Winner buys dinner, Winner gets bragging rights", text: Binding(
                                    get: { prize },
                                    set: { editedAnswers.winnersPrize = $0.isEmpty ? nil : $0 }
                                ), axis: .vertical)
                                .lineLimit(3...6)
                            }
                        }
                    }
                }
                
                // Error Message
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveGoal()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {
                loadBuddyName()
            }
        }
    }
    
    private func getGoalTypeDisplayName() -> String {
        switch goal.goalType {
        case "list_tracker":
            return "List Tracker"
        case "daily_tracker":
            return "Daily Tracker"
        case "list_created_by_user":
            return "List Created By User"
        default:
            return "Not set"
        }
    }
    
    private func getWinningConditionOptions() -> [QuestionOption] {
        // Compute winning condition options directly from editedAnswers
        // This avoids modifying @Published properties during view updates
        var options: [QuestionOption] = []
        
        switch editedAnswers.goalType {
        case "list_tracker":
            if let task = editedAnswers.taskBeingTracked {
                options.append(QuestionOption(
                    id: "first_to_reach_x",
                    title: "First to reach X number of \(task)",
                    description: "First person to complete a target number wins"
                ))
                options.append(QuestionOption(
                    id: "most_by_end_date",
                    title: "Most number of \(task) by an end date",
                    description: "Whoever has the most by the end date wins"
                ))
            }
            
        case "list_created_by_user":
            options.append(QuestionOption(
                id: "first_to_finish",
                title: "First to finish the list",
                description: "First person to complete all items wins"
            ))
            options.append(QuestionOption(
                id: "most_by_end_date",
                title: "Most number of finished items by end date",
                description: "Whoever has completed the most items by the end date wins"
            ))
            
        case "daily_tracker":
            options.append(QuestionOption(
                id: "most_days_by_end_date",
                title: "Most days completed by end date",
                description: "Whoever has the most completed days wins"
            ))
            
            if editedAnswers.keepStreak == true {
                options.append(QuestionOption(
                    id: "longest_streak_by_end_date",
                    title: "Longest streak by end date",
                    description: "Whoever has the longest continuous streak wins"
                ))
                options.append(QuestionOption(
                    id: "first_to_reach_x_days_streak",
                    title: "First to reach X number of days streak",
                    description: "First person to reach a target streak length wins"
                ))
            }
            
            if editedAnswers.trackDailyQuantity == true, let unit = editedAnswers.unitTracked {
                options.append(QuestionOption(
                    id: "most_amount_by_end_date",
                    title: "Most amount of \(unit) completed by end date",
                    description: "Whoever has accumulated the most \(unit) wins"
                ))
                options.append(QuestionOption(
                    id: "first_to_complete_x_amount",
                    title: "First person to complete X number of \(unit)",
                    description: "First person to reach a target amount wins"
                ))
            }
            
        default:
            break
        }
        
        return options
    }
    
    private func loadBuddyName() {
        guard let buddyId = goal.buddyId else { return }
        
        Task {
            let supabaseService = SupabaseService.shared
            if let buddyProfile = try? await supabaseService.fetchProfile(userId: buddyId) {
                await MainActor.run {
                    buddyName = buddyProfile.name ?? buddyProfile.username ?? "Buddy"
                }
            } else {
                await MainActor.run {
                    buddyName = "Buddy"
                }
            }
        }
    }
    
    private func saveGoal() async {
        isSaving = true
        errorMessage = nil
        
        do {
            let supabaseService = SupabaseService.shared
            try await supabaseService.updateGoal(
                goalId: goal.id,
                name: editedAnswers.goalName,
                taskBeingTracked: editedAnswers.taskBeingTracked,
                listItems: editedAnswers.listItems,
                keepStreak: editedAnswers.keepStreak,
                trackDailyQuantity: editedAnswers.trackDailyQuantity,
                unitTracked: editedAnswers.unitTracked,
                challengeOrFriendly: editedAnswers.challengeOrFriendly,
                winningCondition: editedAnswers.winningCondition,
                winningNumber: editedAnswers.winningNumber,
                endDate: editedAnswers.endDate,
                winnersPrize: editedAnswers.winnersPrize
            )
            
            // Reload goals to get updated data
            await viewModel.loadGoals()
            
            // Wait a moment for @Published property to update
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            // Try to grab the freshly reloaded goal from the viewModel for immediate UI update
            await MainActor.run {
                if let refreshedGoalWithProgress = viewModel.goals.first(where: { $0.goal.id == goal.id }) {
                    // Use the full GoalWithProgress from viewModel to ensure we have latest data
                    onSave?(refreshedGoalWithProgress.goal)
                } else {
                    // Fallback: construct a local updated goal so UI still updates immediately
                    let updatedGoal = Goal(
                        id: goal.id,
                        name: editedAnswers.goalName ?? goal.name,
                        trackingMethod: goal.trackingMethod,
                        creatorId: goal.creatorId,
                        buddyId: goal.buddyId,
                        createdAt: goal.createdAt,
                        updatedAt: Date(),
                        goalType: goal.goalType,
                        taskBeingTracked: editedAnswers.taskBeingTracked,
                        listItems: editedAnswers.listItems,
                        keepStreak: editedAnswers.keepStreak,
                        trackDailyQuantity: editedAnswers.trackDailyQuantity,
                        unitTracked: editedAnswers.unitTracked,
                        challengeOrFriendly: editedAnswers.challengeOrFriendly,
                        winningCondition: editedAnswers.winningCondition,
                        winningNumber: editedAnswers.winningNumber,
                        endDate: editedAnswers.endDate,
                        winnersPrize: editedAnswers.winnersPrize,
                        winnerUserId: goal.winnerUserId,
                        loserUserId: goal.loserUserId,
                        goalStatus: goal.goalStatus
                    )
                    onSave?(updatedGoal)
                }
                
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
}
