//
//  GoalDetailView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: GoalsViewModel
    @State var goalWithProgress: GoalWithProgress
    
    @State private var myProgress: GoalProgress?
    @State private var buddyProgress: GoalProgress?
    @State private var numericInput: String = ""
    @State private var newListItem: String = ""
    @State private var dailyQuantityInput: String = ""
    @State private var creatorName: String = "Me"
    @State private var buddyName: String? = nil
    @State private var showQuantityPopup: Bool = false
    @State private var quantityInput: String = ""
    @State private var showWinnerModal: Bool = false
    @State private var isWinner: Bool = false
    @State private var showEditGoal: Bool = false
    @State private var showMarkFinishedAlert: Bool = false
    
    var isCreator: Bool {
        guard let currentUserId = authViewModel.currentUserId else { return false }
        return goalWithProgress.goal.creatorId == currentUserId
    }
    
    /// Challenge details card
    private var challengeDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Challenge Details")
                .font(.headline)
            
            if let objectiveText = formattedChallengeObjective(goalWithProgress.goal) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Challenge Objective")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(objectiveText)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            
            if let prize = goalWithProgress.goal.winnersPrize, !prize.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Challenge Stakes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(prize)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// Human-readable challenge objective
    private func formattedChallengeObjective(_ goal: Goal) -> String? {
        guard let raw = goal.winningCondition, !raw.isEmpty else { return nil }
        let lc = raw.lowercased()
        let unit = goal.unitTracked ?? "units"
        let number = goal.winningNumber
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let endDateString = goal.endDate.map { dateFormatter.string(from: $0) }
        
        if lc.contains("first to reach") || lc.contains("first_to_reach_x") {
            if let number = number {
                return "First to reach \(number) \(unit)"
            }
            return "First to reach the target"
        } else if lc.contains("first to complete") || lc.contains("first_to_complete_x_amount") {
            if let number = number {
                return "First to complete \(number) \(unit)"
            }
            return "First to complete the required amount"
        } else if lc.contains("first to finish") || lc.contains("first_to_finish") {
            return "First to finish the list"
        } else if lc.contains("most_by_end_date") ||
                    (lc.contains("most") && (lc.contains("end date") || lc.contains("end_date"))) {
            if let endDateString = endDateString {
                return "Most completed by \(endDateString)"
            }
            return "Most completed by the deadline"
        }
        
        // Fallback: prettify the raw string
        let prettified = raw
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prettified.isEmpty else { return nil }
        return prettified.prefix(1).capitalized + prettified.dropFirst()
    }
    
    var myProgressData: GoalProgress? {
        // Always read from viewModel.goals first (source of truth), fallback to goalWithProgress
        let sourceGoal = viewModel.goals.first(where: { $0.goal.id == goalWithProgress.goal.id }) ?? goalWithProgress
        
        guard let currentUserId = authViewModel.currentUserId else { return nil }
        if isCreator {
            return sourceGoal.creatorProgress
        } else {
            return sourceGoal.buddyProgress
        }
    }
    
    var buddyProgressData: GoalProgress? {
        // Always read from viewModel.goals first (source of truth), fallback to goalWithProgress
        let sourceGoal = viewModel.goals.first(where: { $0.goal.id == goalWithProgress.goal.id }) ?? goalWithProgress
        
        guard let currentUserId = authViewModel.currentUserId else { return nil }
        if isCreator {
            return sourceGoal.buddyProgress
        } else {
            return sourceGoal.creatorProgress
        }
    }
    
    var visuals: [VisualType] {
        GoalVisualSelector.getVisuals(for: goalWithProgress.goal)
    }
    
    /// Check if goal is finished for the current user (and they shouldn't be able to update progress)
    private var isGoalFinishedForCurrentUser: Bool {
        // If goal is fully finished, no one can update
        if goalWithProgress.goal.goalStatus == .finished {
            return true
        }
        
        // If goal is pending_finish and current user has seen the message, they can't update
        if goalWithProgress.goal.goalStatus == .pendingFinish {
            let myProg = myProgressData ?? myProgress
            return myProg?.hasSeenWinnerMessage == true
        }
        
        // For all other statuses (active, nil), user can still update
        return false
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    goalHeader
                    
                    // Input section (only show if goal is not finished for current user)
                    if !isGoalFinishedForCurrentUser {
                        inputSection
                    }
                    
                    // Render visuals based on goal type
                    ForEach(visuals, id: \.self) { visualType in
                        renderVisual(visualType)
                    }
                    
                    // Challenge details (objective and stakes)
                    if goalWithProgress.goal.challengeOrFriendly == "challenge" {
                        challengeDetailsSection
                    }
                }
                .padding()
            }
            
            // Quantity popup overlay - at the ZStack level so it appears over everything
            if showQuantityPopup {
                QuantityInputPopup(
                    quantityInput: $quantityInput,
                    unit: goalWithProgress.goal.unitTracked,
                    onSubmit: {
                        markTodayCompleteWithQuantity()
                        showQuantityPopup = false
                    },
                    onCancel: {
                        quantityInput = ""
                        showQuantityPopup = false
                    }
                )
            }
            
            // Winner modal overlay
            if showWinnerModal {
                WinnerModal(
                    goalName: goalWithProgress.goal.name,
                    buddyName: getOtherPersonName(),
                    isWinner: isWinner,
                    winnersPrize: goalWithProgress.goal.winnersPrize,
                    onClose: {
                        handleWinnerModalClose()
                    }
                )
            }
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Only show menu for creator
                if isCreator {
                    Menu {
                        Button(action: {
                            showEditGoal = true
                        }) {
                            Label("Edit Goal", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            showMarkFinishedAlert = true
                        }) {
                            Label("Mark Goal as Finished", systemImage: "checkmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                    }
                } else {
                    // Empty view when not creator to maintain toolbar space
                    EmptyView()
                }
            }
        }
        .sheet(isPresented: $showEditGoal, onDismiss: {
            // When edit sheet is dismissed, refresh the goal data immediately
            // First, sync with current viewModel.goals (should already be updated)
            syncGoalFromViewModel()
            refreshProgressState()
            
            // Then reload in background to ensure we have the absolute latest data
            Task {
                await viewModel.loadGoals()
                await MainActor.run {
                    syncGoalFromViewModel()
                    refreshProgressState()
                }
            }
        }) {
            EditGoalView(
                goal: goalWithProgress.goal,
                viewModel: viewModel,
                onSave: { updatedGoal in
                    // Update local state immediately with the refreshed goal
                    goalWithProgress = GoalWithProgress(
                        goal: updatedGoal,
                        creatorProgress: goalWithProgress.creatorProgress,
                        buddyProgress: goalWithProgress.buddyProgress
                    )
                    refreshProgressState()
                }
            )
        }
        .alert("Mark Goal as Finished", isPresented: $showMarkFinishedAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Mark Finished", role: .destructive) {
                markGoalAsFinished()
            }
        } message: {
            Text("Are you sure you want to mark this goal as finished? This action cannot be undone.")
        }
        .onAppear {
            // First, sync with viewModel.goals if it has data (might be fresh from navigation)
            syncGoalFromViewModel()
            refreshProgressState()
            
            // Check for winner modal IMMEDIATELY using existing data (no wait for server)
            checkAndShowWinnerModalSync()
            
            // Load user names (non-blocking)
            Task {
                await loadUserNames()
            }
            
            // Reload goals from database in background (for fresh data, but don't wait)
            Task {
                await viewModel.loadGoals()
                // After reload, sync again with the fresh data and re-check modal
                // Wrap state modifications in MainActor to ensure thread safety
                await MainActor.run {
                    syncGoalFromViewModel()
                    refreshProgressState()
                }
                await checkAndShowWinnerModal()
            }
        }
        .onChange(of: viewModel.goals) { newGoals in
            // When viewModel.goals changes, always sync and refresh to show latest progress
            // This ensures the UI updates immediately when goals are reloaded
            syncGoalFromViewModel()
            refreshProgressState()
            
            // Check for winner modal after goals update
            Task {
                await checkAndShowWinnerModal()
            }
        }
    }
    
    private var goalHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(goalWithProgress.goal.name)
                .font(.title)
                .fontWeight(.bold)
                .id(goalWithProgress.goal.name) // Force update when name changes
            
            if goalWithProgress.goal.challengeOrFriendly == "challenge" {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.orange)
                    Text("Challenge Mode")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func renderVisual(_ visualType: VisualType) -> some View {
        switch visualType {
        case .list:
            let myItems = myProgress?.listItems ?? myProgressData?.listItems ?? []
            let buddyItems = buddyProgress?.listItems ?? buddyProgressData?.listItems
            let showBoth = goalWithProgress.goal.buddyId != nil
            ListVisual(
                items: myItems,
                taskName: goalWithProgress.goal.taskBeingTracked,
                buddyItems: buddyItems,
                showBothUsers: showBoth,
                myName: isCreator ? creatorName : (buddyName ?? "Me"),
                buddyName: goalWithProgress.goal.buddyId != nil ? (isCreator ? buddyName : creatorName) : nil
            )
            
        case .userCreatedList:
            if let originalItems = goalWithProgress.goal.listItems {
                let myItems = myProgress?.listItems ?? myProgressData?.listItems ?? []
                // For buddy items, use empty array if buddy exists but no progress yet
                // This ensures the buddy column shows up even if they haven't opened the goal
                let buddyItems: [GoalListItem]? = {
                    if goalWithProgress.goal.buddyId != nil {
                        // If buddy exists, show their progress (even if empty array)
                        return buddyProgress?.listItems ?? buddyProgressData?.listItems ?? []
                    }
                    return nil
                }()
                UserCreatedListVisual(
                    originalItems: originalItems,
                    myCompletedItems: myItems,
                    buddyCompletedItems: buddyItems,
                    myName: isCreator ? creatorName : (buddyName ?? "Me"),
                    buddyName: goalWithProgress.goal.buddyId != nil ? (isCreator ? buddyName : creatorName) : nil,
                    onItemTap: isGoalFinishedForCurrentUser ? nil : { item in
                        toggleListItemCompletion(item)
                    }
                )
            }
            
        case .sumBox:
            // Show both users' counts if buddy exists
            let myItems = myProgress?.listItems ?? myProgressData?.listItems ?? []
            let myCount = myItems.count
            let label = goalWithProgress.goal.taskBeingTracked
            if goalWithProgress.goal.buddyId != nil {
                let buddyItems = buddyProgress?.listItems ?? buddyProgressData?.listItems ?? []
                let buddyCount = buddyItems.count
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isCreator ? creatorName : (buddyName ?? "Me"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SumBoxVisual(count: myCount, label: label)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isCreator ? (buddyName ?? "Buddy") : creatorName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SumBoxVisual(count: buddyCount, label: label)
                    }
                }
            } else {
                SumBoxVisual(count: myCount, label: label)
            }
            
        case .sumBoxGoal:
            let myCurrent = getCurrentCount()
            // For list_created_by_user, use total items in original list as goal
            // For other types, use winningNumber
            let goal = goalWithProgress.goal.goalType == "list_created_by_user" 
                ? max(goalWithProgress.goal.listItems?.count ?? 1, 1)
                : (goalWithProgress.goal.winningNumber ?? 1)
            let label = getSumBoxLabel()
            if goalWithProgress.goal.buddyId != nil {
                let buddyCurrent = getBuddyCurrentCount()
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isCreator ? creatorName : (buddyName ?? "Me"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SumBoxGoalVisual(current: myCurrent, goal: goal, label: label)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isCreator ? (buddyName ?? "Buddy") : creatorName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SumBoxGoalVisual(current: buddyCurrent, goal: goal, label: label)
                    }
                }
            } else {
                SumBoxGoalVisual(current: myCurrent, goal: goal, label: label)
            }
            
        case .endDateBox:
            if let endDate = goalWithProgress.goal.endDate {
                EndDateBoxVisual(endDate: endDate, label: "Challenge Ends")
            } else {
                // Debug: Show message if endDate is missing
                VStack(alignment: .leading, spacing: 8) {
                    Text("End Date Box")
                        .font(.headline)
                    Text("End date not set for this goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
        case .calendarWithCheck:
            let myCompletedDays = myProgress?.completedDays ?? myProgressData?.completedDays ?? []
            let buddyCompletedDays = goalWithProgress.goal.buddyId != nil ? (buddyProgress?.completedDays ?? buddyProgressData?.completedDays ?? []) : nil
            CalendarWithCheckVisual(
                myCompletedDays: myCompletedDays,
                buddyCompletedDays: buddyCompletedDays,
                onDateTap: isGoalFinishedForCurrentUser ? nil : { dateString in
                    toggleDayCompletion(dateString: dateString)
                },
                isCreator: isCreator,
                creatorName: creatorName,
                buddyName: buddyName
            )
            
        case .streakCounter:
            let myCompletedDays = myProgress?.completedDays ?? myProgressData?.completedDays ?? []
            let myStreaks = calculateStreak(from: myCompletedDays)
            if goalWithProgress.goal.buddyId != nil {
                let buddyCompletedDays = buddyProgress?.completedDays ?? buddyProgressData?.completedDays ?? []
                let buddyStreaks = calculateStreak(from: buddyCompletedDays)
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isCreator ? creatorName : (buddyName ?? "Me"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        StreakCounterVisual(currentStreak: myStreaks.current, maxStreak: myStreaks.max)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isCreator ? (buddyName ?? "Buddy") : creatorName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        StreakCounterVisual(currentStreak: buddyStreaks.current, maxStreak: buddyStreaks.max)
                    }
                }
            } else {
                StreakCounterVisual(currentStreak: myStreaks.current, maxStreak: myStreaks.max)
            }
            
        case .totalDaysCount:
            let myCount = (myProgress?.completedDays ?? myProgressData?.completedDays ?? []).count
            if goalWithProgress.goal.buddyId != nil {
                let buddyCount = (buddyProgress?.completedDays ?? buddyProgressData?.completedDays ?? []).count
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isCreator ? creatorName : (buddyName ?? "Me"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TotalDaysCountVisual(count: myCount)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isCreator ? (buddyName ?? "Buddy") : creatorName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TotalDaysCountVisual(count: buddyCount)
                    }
                }
            } else {
                TotalDaysCountVisual(count: myCount)
            }
            
        case .barChart:
            if let myEntries = getDailyQuantityEntries() {
                let unit = goalWithProgress.goal.unitTracked ?? ""
                let buddyEntries = getBuddyDailyQuantityEntries()
                BarChartVisual(
                    myEntries: myEntries,
                    buddyEntries: buddyEntries,
                    unit: unit,
                    timeRange: .week,
                    isCreator: isCreator,
                    creatorName: creatorName,
                    buddyName: buddyName
                )
            }
            
        case .barTotals:
            if let myEntries = getDailyQuantityEntries() {
                let unit = goalWithProgress.goal.unitTracked ?? ""
                if goalWithProgress.goal.buddyId != nil, let buddyEntries = getBuddyDailyQuantityEntries() {
                    // Show both users' totals side by side
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isCreator ? creatorName : (buddyName ?? "Me"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            BarTotalsVisual(entries: myEntries, unit: unit)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isCreator ? (buddyName ?? "Buddy") : creatorName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            BarTotalsVisual(entries: buddyEntries, unit: unit)
                        }
                    }
                } else {
                    BarTotalsVisual(entries: myEntries, unit: unit)
                }
            }
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Update Progress")
                .font(.headline)
            
            if goalWithProgress.goal.goalType == "list_tracker" {
                // Add new item input
                HStack {
                    TextField("Enter \(goalWithProgress.goal.taskBeingTracked ?? "item")", text: $newListItem)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Add") {
                        addListItem()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newListItem.isEmpty)
                }
            } else if goalWithProgress.goal.goalType == "list_created_by_user" {
                // Items are checked from the user created list visual
                Text("Tap items in the list below to mark them as complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if goalWithProgress.goal.goalType == "daily_tracker" {
                VStack(alignment: .leading, spacing: 12) {
                    let isTodayCompleted = checkIfTodayIsCompleted()
                    Button(isTodayCompleted ? "Today Is Completed" : "Mark Today Complete") {
                        if !isTodayCompleted {
                            if goalWithProgress.goal.trackDailyQuantity == true {
                                // Show quantity popup
                                quantityInput = ""
                                showQuantityPopup = true
                            } else {
                                // Just mark today complete without quantity
                                markTodayComplete()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isTodayCompleted)
                    .frame(maxWidth: .infinity)
                }
            } else {
                // Legacy input methods
                legacyInputView
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var legacyInputView: some View {
        switch goalWithProgress.goal.trackingMethod {
        case .inputNumbers:
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
                            await viewModel.loadGoals()
                            // Check for winner modal after progress update
                            await checkAndShowWinnerModal()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        case .trackDaysCompleted:
            let isTodayCompleted = checkIfTodayIsCompleted()
            Button(isTodayCompleted ? "Today Is Completed" : "Mark Today Complete") {
                if !isTodayCompleted {
                    markTodayComplete()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isTodayCompleted)
            .frame(maxWidth: .infinity)
        case .inputList:
            HStack {
                TextField("Enter item", text: $newListItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Add") {
                    addListItem()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newListItem.isEmpty)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func getGoalTypeDisplayName(_ goalType: String) -> String {
        switch goalType {
        case "list_tracker":
            return "List Tracker"
        case "daily_tracker":
            return "Daily Tracker"
        case "list_created_by_user":
            return "List Created By User"
        default:
            return goalWithProgress.goal.trackingMethod.displayName
        }
    }
    
    private func getCurrentCount() -> Int {
        if goalWithProgress.goal.goalType == "daily_tracker" && goalWithProgress.goal.trackDailyQuantity == true {
            // For daily tracker with quantity, return total quantity
            return Int(myProgress?.numericValue ?? myProgressData?.numericValue ?? 0)
        } else {
            // For list items, return count
            return (myProgress?.listItems ?? myProgressData?.listItems ?? []).count
        }
    }
    
    private func getBuddyCurrentCount() -> Int {
        if goalWithProgress.goal.goalType == "daily_tracker" && goalWithProgress.goal.trackDailyQuantity == true {
            // For daily tracker with quantity, return total quantity
            return Int(buddyProgress?.numericValue ?? buddyProgressData?.numericValue ?? 0)
        } else {
            // For list items, return count
            return (buddyProgress?.listItems ?? buddyProgressData?.listItems ?? []).count
        }
    }
    
    private func getSumBoxLabel() -> String? {
        if goalWithProgress.goal.goalType == "daily_tracker" && goalWithProgress.goal.trackDailyQuantity == true {
            return goalWithProgress.goal.unitTracked
        } else {
            return goalWithProgress.goal.taskBeingTracked
        }
    }
    
    private func getDailyQuantityEntries() -> [DailyQuantityEntry]? {
        guard goalWithProgress.goal.trackDailyQuantity == true else {
            return nil
        }
        let unit = goalWithProgress.goal.unitTracked ?? "units"
        
        // Parse daily quantities from list_items
        // For daily tracker with quantity, we store entries in list_items as {title: "quantity", date: date}
        let listItems = myProgress?.listItems ?? myProgressData?.listItems ?? []
        var entries: [DailyQuantityEntry] = []
        
        for item in listItems {
            // Try to parse quantity from title (stored as string representation of number)
            if let quantity = Double(item.title) {
                entries.append(DailyQuantityEntry(
                    id: item.id,
                    date: item.date,
                    quantity: quantity,
                    unit: unit
                ))
            }
        }
        
        // If no entries in list_items, use completedDays and numericValue as fallback
        if entries.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let completedDays = myProgress?.completedDays ?? myProgressData?.completedDays ?? []
            let totalQuantity = myProgress?.numericValue ?? myProgressData?.numericValue ?? 0
            
            // Distribute total quantity across days (simple approach for MVP)
            let avgPerDay = completedDays.isEmpty ? 0 : totalQuantity / Double(completedDays.count)
            
            for dayString in completedDays {
                if let date = dateFormatter.date(from: dayString) {
                    entries.append(DailyQuantityEntry(
                        date: date,
                        quantity: avgPerDay,
                        unit: unit
                    ))
                }
            }
        }
        
        // Always return an array (even if empty) so the bar chart can render with zeros
        return entries.sorted(by: { $0.date < $1.date })
    }
    
    private func getBuddyDailyQuantityEntries() -> [DailyQuantityEntry]? {
        guard goalWithProgress.goal.trackDailyQuantity == true else {
            return nil
        }
        let unit = goalWithProgress.goal.unitTracked ?? "units"
        
        let listItems = buddyProgress?.listItems ?? buddyProgressData?.listItems ?? []
        var entries: [DailyQuantityEntry] = []
        
        for item in listItems {
            if let quantity = Double(item.title) {
                entries.append(DailyQuantityEntry(
                    id: item.id,
                    date: item.date,
                    quantity: quantity,
                    unit: unit
                ))
            }
        }
        
        if entries.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let completedDays = buddyProgress?.completedDays ?? buddyProgressData?.completedDays ?? []
            let totalQuantity = buddyProgress?.numericValue ?? buddyProgressData?.numericValue ?? 0
            
            let avgPerDay = completedDays.isEmpty ? 0 : totalQuantity / Double(completedDays.count)
            
            for dayString in completedDays {
                if let date = dateFormatter.date(from: dayString) {
                    entries.append(DailyQuantityEntry(
                        date: date,
                        quantity: avgPerDay,
                        unit: unit
                    ))
                }
            }
        }
        
        return entries.sorted(by: { $0.date < $1.date })
    }
    
    // MARK: - Actions
    
    private func addListItem() {
        guard !newListItem.isEmpty else { return }
        guard !isGoalFinishedForCurrentUser else { return } // Don't allow updates if goal is finished
        
        let newEntry = GoalListItem(title: newListItem, date: Date())
        let itemToAdd = newListItem
        newListItem = ""
        
        // Optimistic update
        var currentItems = myProgress?.listItems ?? myProgressData?.listItems ?? []
        currentItems.append(newEntry)
        
        updateMyProgress(listItems: currentItems)
        
        // Check for winner immediately (optimistic) before server sync
        checkWinnerLocally()
        
        // Sync with server
        Task {
            await viewModel.updateGoalProgress(
                goalId: goalWithProgress.goal.id,
                listItems: currentItems
            )
            await viewModel.loadGoals()
            // Check for winner modal after progress update (server confirmation)
            await checkAndShowWinnerModal()
        }
    }
    
    private func toggleListItemCompletion(_ item: String) {
        guard goalWithProgress.goal.goalType == "list_created_by_user" else { return }
        guard !isGoalFinishedForCurrentUser else { return } // Don't allow updates if goal is finished
        
        var currentItems = myProgress?.listItems ?? myProgressData?.listItems ?? []
        let normalizedItem = item.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Check if already completed
        if let index = currentItems.firstIndex(where: { $0.title.lowercased().trimmingCharacters(in: .whitespaces) == normalizedItem }) {
            // Remove if already completed
            currentItems.remove(at: index)
        } else {
            // Add if not completed
            currentItems.append(GoalListItem(title: item, date: Date()))
        }
        
        updateMyProgress(listItems: currentItems)
        
        // Check for winner immediately (optimistic) before server sync
        checkWinnerLocally()
        
        // Sync with server
        Task {
            await viewModel.updateGoalProgress(
                goalId: goalWithProgress.goal.id,
                listItems: currentItems
            )
            await viewModel.loadGoals()
            // Check for winner modal after progress update (server confirmation)
            await checkAndShowWinnerModal()
        }
    }
    
    private func markTodayComplete() {
        guard !isGoalFinishedForCurrentUser else { return } // Don't allow updates if goal is finished
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        var days = myProgress?.completedDays ?? myProgressData?.completedDays ?? []
        if !days.contains(today) {
            days.append(today)
            updateMyProgress(completedDays: days)
            
            // Check for winner immediately (optimistic) before server sync
            checkWinnerLocally()
            
            Task {
                await viewModel.updateGoalProgress(
                    goalId: goalWithProgress.goal.id,
                    numericValue: nil,
                    completedDays: days
                )
                await viewModel.loadGoals()
                // Check for winner modal after progress update (server confirmation)
                await checkAndShowWinnerModal()
            }
        }
    }
    
    private func markTodayCompleteWithQuantity() {
        guard let quantity = Double(quantityInput), !quantityInput.isEmpty else { return }
        guard !isGoalFinishedForCurrentUser else { return } // Don't allow updates if goal is finished
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        let todayDate = Date()
        
        // Mark today as completed if not already
        var days = myProgress?.completedDays ?? myProgressData?.completedDays ?? []
        if !days.contains(today) {
            days.append(today)
        }
        
        // Add quantity entry to list_items (for bar chart)
        var currentItems = myProgress?.listItems ?? myProgressData?.listItems ?? []
        // Store quantity as title, date as the entry date
        let quantityItem = GoalListItem(
            title: String(quantity),
            date: todayDate
        )
        currentItems.append(quantityItem)
        
        // Update total quantity
        let currentTotal = myProgress?.numericValue ?? myProgressData?.numericValue ?? 0
        let newTotal = currentTotal + quantity
        
        updateMyProgress(listItems: currentItems, completedDays: days, numericValue: newTotal)
        
        // Clear input
        quantityInput = ""
        
        // Check for winner immediately (optimistic) before server sync
        checkWinnerLocally()
        
        Task {
            await viewModel.updateGoalProgress(
                goalId: goalWithProgress.goal.id,
                numericValue: newTotal,
                completedDays: days,
                listItems: currentItems
            )
            await viewModel.loadGoals()
            // Check for winner modal after progress update (server confirmation)
            await checkAndShowWinnerModal()
        }
    }
    
    private func toggleDayCompletion(dateString: String) {
        guard !isGoalFinishedForCurrentUser else { return } // Don't allow updates if goal is finished
        
        var days = myProgress?.completedDays ?? myProgressData?.completedDays ?? []
        if let index = days.firstIndex(of: dateString) {
            days.remove(at: index)
        } else {
            days.append(dateString)
        }
        updateMyProgress(completedDays: days)
        
        Task {
            await viewModel.updateGoalProgress(
                goalId: goalWithProgress.goal.id,
                numericValue: nil,
                completedDays: days
            )
            await viewModel.loadGoals()
            // Check for winner modal after progress update
            await checkAndShowWinnerModal()
        }
    }
    
    private func addDailyQuantity() {
        guard let quantity = Double(dailyQuantityInput), !dailyQuantityInput.isEmpty else { return }
        let quantityToAdd = quantity
        dailyQuantityInput = ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        let todayDate = Date()
        
        // Mark today as completed if not already
        var days = myProgress?.completedDays ?? myProgressData?.completedDays ?? []
        if !days.contains(today) {
            days.append(today)
        }
        
        // Add quantity entry to list_items (for bar chart)
        var currentItems = myProgress?.listItems ?? myProgressData?.listItems ?? []
        // Store quantity as title, date as the entry date
        let quantityEntry = GoalListItem(title: String(quantityToAdd), date: todayDate)
        currentItems.append(quantityEntry)
        
        // Update total quantity
        let currentTotal = myProgress?.numericValue ?? myProgressData?.numericValue ?? 0
        let newTotal = currentTotal + quantityToAdd
        
        updateMyProgress(listItems: currentItems, completedDays: days, numericValue: newTotal)
        
        Task {
            await viewModel.updateGoalProgress(
                goalId: goalWithProgress.goal.id,
                numericValue: newTotal,
                completedDays: days,
                listItems: currentItems
            )
            await viewModel.loadGoals()
            // Check for winner modal after progress update
            await checkAndShowWinnerModal()
        }
    }
    
    private func updateMyProgress(listItems: [GoalListItem]? = nil, completedDays: [String]? = nil, numericValue: Double? = nil) {
        let currentUserId = isCreator ? goalWithProgress.goal.creatorId : (goalWithProgress.goal.buddyId ?? UUID())
        
        if var existing = myProgress {
            if let items = listItems { existing.listItems = items }
            if let days = completedDays { existing.completedDays = days }
            if let value = numericValue { existing.numericValue = value }
            myProgress = existing
        } else {
            myProgress = GoalProgress(
                id: UUID(),
                goalId: goalWithProgress.goal.id,
                userId: currentUserId,
                numericValue: numericValue,
                completedDays: completedDays,
                listItems: listItems
            )
        }
        
        // Update goalWithProgress
        if isCreator {
            goalWithProgress.creatorProgress = myProgress
        } else {
            goalWithProgress.buddyProgress = myProgress
        }
    }
    
    /// Sync goalWithProgress from viewModel.goals (source of truth)
    private func syncGoalFromViewModel() {
        // Find the matching goal in viewModel.goals and update our local state
        if let updatedGoal = viewModel.goals.first(where: { $0.goal.id == goalWithProgress.goal.id }) {
            // Always create a new instance to force SwiftUI to detect the change
            // The Equatable implementation only checks IDs, so we need to always update
            // to ensure property changes (like name) are detected
            let newGoalWithProgress = GoalWithProgress(
                goal: updatedGoal.goal,
                creatorProgress: updatedGoal.creatorProgress,
                buddyProgress: updatedGoal.buddyProgress
            )
            
            // Only update if something actually changed to avoid unnecessary view updates
            // But always update to ensure SwiftUI detects property changes
            goalWithProgress = newGoalWithProgress
        }
    }
    
    /// Refresh the local progress state from goalWithProgress
    private func refreshProgressState() {
        // Get current progress data from goalWithProgress
        let currentMyProgress = myProgressData
        let currentBuddyProgress = buddyProgressData
        
        // Always assign new instances to force SwiftUI to detect changes
        // Even if the data is the same, creating new instances ensures view updates
        if let myProg = currentMyProgress {
            myProgress = GoalProgress(
                id: myProg.id,
                goalId: myProg.goalId,
                userId: myProg.userId,
                numericValue: myProg.numericValue,
                completedDays: myProg.completedDays,
                listItems: myProg.listItems,
                updatedAt: myProg.updatedAt,
                hasSeenWinnerMessage: myProg.hasSeenWinnerMessage
            )
        } else {
            myProgress = nil
        }
        
        if let buddyProg = currentBuddyProgress {
            buddyProgress = GoalProgress(
                id: buddyProg.id,
                goalId: buddyProg.goalId,
                userId: buddyProg.userId,
                numericValue: buddyProg.numericValue,
                completedDays: buddyProg.completedDays,
                listItems: buddyProg.listItems,
                updatedAt: buddyProg.updatedAt,
                hasSeenWinnerMessage: buddyProg.hasSeenWinnerMessage
            )
        } else {
            buddyProgress = nil
        }
        
        // If buddy exists but no progress entry yet, create an empty one locally
        // This ensures the buddy column shows up immediately
        if goalWithProgress.goal.buddyId != nil && buddyProgress == nil && buddyProgressData == nil {
            buddyProgress = GoalProgress(
                id: UUID(),
                goalId: goalWithProgress.goal.id,
                userId: goalWithProgress.goal.buddyId!,
                numericValue: nil,
                completedDays: nil,
                listItems: [] // Empty array for user created list goals
            )
        }
        
        if let progress = myProgressData, goalWithProgress.goal.trackingMethod == .inputNumbers {
            numericInput = progress.numericValue != nil ? String(Int(progress.numericValue!)) : ""
        }
    }
    
    private func loadUserNames() async {
        let supabaseService = SupabaseService.shared
        
        // Load creator name
        if let creatorProfile = try? await supabaseService.fetchProfile(userId: goalWithProgress.goal.creatorId) {
            creatorName = creatorProfile.name ?? creatorProfile.username ?? "Me"
        }
        
        // Load buddy name if buddy exists
        if let buddyId = goalWithProgress.goal.buddyId {
            if let buddyProfile = try? await supabaseService.fetchProfile(userId: buddyId) {
                buddyName = buddyProfile.name ?? buddyProfile.username ?? "Buddy"
            } else {
                buddyName = "Buddy"
            }
        }
    }
    
    private func checkIfTodayIsCompleted() -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let completedDays = myProgress?.completedDays ?? myProgressData?.completedDays ?? []
        return completedDays.contains(today)
    }
    
    /// Check if winner modal should be shown (synchronous version for immediate check)
    private func checkAndShowWinnerModalSync() {
        let latestGoal = goalWithProgress.goal
        
        print("🔍 Checking winner modal conditions (sync):")
        print("   Goal: \(latestGoal.name)")
        print("   Challenge/Friendly: \(latestGoal.challengeOrFriendly ?? "nil")")
        print("   Goal Status: \(latestGoal.goalStatus?.rawValue ?? "nil")")
        print("   Winner User ID: \(latestGoal.winnerUserId?.uuidString ?? "nil")")
        
        // Only show for challenge goals with pending_finish status
        guard latestGoal.challengeOrFriendly == "challenge",
              latestGoal.goalStatus == .pendingFinish else {
            return
        }
        
        // Check if current user has already seen the message
        guard let currentUserId = authViewModel.currentUserId else { return }
        
        // Get the progress data for current user
        let myProg = isCreator ? goalWithProgress.creatorProgress : goalWithProgress.buddyProgress
        
        if myProg?.hasSeenWinnerMessage == true {
            return // Already seen
        }
        
        // Determine if current user is winner or loser
        guard let winnerId = latestGoal.winnerUserId else {
            return
        }
        
        isWinner = winnerId == currentUserId
        print("   🎉 Showing winner modal immediately!")
        print("      Is Winner: \(isWinner)")
        showWinnerModal = true
    }
    
    /// Check if winner modal should be shown
    private func checkAndShowWinnerModal() async {
        // Always check the latest goal data from viewModel (source of truth)
        guard let latestGoalWithProgress = viewModel.goals.first(where: { $0.goal.id == goalWithProgress.goal.id }) else {
            print("🔍 Winner modal check - Goal not found in viewModel.goals")
            return
        }
        
        let latestGoal = latestGoalWithProgress.goal
        
        print("🔍 Checking winner modal conditions:")
        print("   Goal: \(latestGoal.name)")
        print("   Challenge/Friendly: \(latestGoal.challengeOrFriendly ?? "nil")")
        print("   Goal Status: \(latestGoal.goalStatus?.rawValue ?? "nil")")
        print("   Winner User ID: \(latestGoal.winnerUserId?.uuidString ?? "nil")")
        
        // Only show for challenge goals with pending_finish status
        guard latestGoal.challengeOrFriendly == "challenge",
              latestGoal.goalStatus == .pendingFinish else {
            print("   ⏸️ Skipping - Not a challenge or status not pending_finish")
            return
        }
        
        // Check if current user has already seen the message
        guard let currentUserId = authViewModel.currentUserId else {
            print("   ⏸️ Skipping - No current user ID")
            return
        }
        
        // Get the latest progress data for current user
        let myProg = isCreator ? latestGoalWithProgress.creatorProgress : latestGoalWithProgress.buddyProgress
        
        print("   📋 User Progress - Has seen message: \(myProg?.hasSeenWinnerMessage ?? false)")
        
        if myProg?.hasSeenWinnerMessage == true {
            print("   📭 Winner modal already seen by user - skipping")
            return // Already seen
        }
        
        // Determine if current user is winner or loser
        guard let winnerId = latestGoal.winnerUserId else {
            print("   ⚠️ Goal status is pending_finish but no winner_user_id set")
            return
        }
        
        isWinner = winnerId == currentUserId
        print("   🎉 Showing winner modal!")
        print("      Is Winner: \(isWinner)")
        print("      Winner ID: \(winnerId)")
        print("      Current User ID: \(currentUserId)")
        
        // Update goalWithProgress to ensure we have latest data
        goalWithProgress = latestGoalWithProgress
        refreshProgressState()
        
        // Show the modal on the main thread
        await MainActor.run {
            print("   ✅ Setting showWinnerModal = true")
            showWinnerModal = true
        }
        
        print("   ✅ Winner modal check complete - showWinnerModal: \(showWinnerModal)")
    }
    
    /// Check for winner locally (optimistic check before server confirmation)
    private func checkWinnerLocally() {
        // Only check for challenge goals that are still active
        guard goalWithProgress.goal.challengeOrFriendly == "challenge",
              goalWithProgress.goal.goalStatus != .finished,
              goalWithProgress.goal.goalStatus != .pendingFinish,
              let buddyId = goalWithProgress.goal.buddyId,
              let winningCondition = goalWithProgress.goal.winningCondition else {
            return
        }
        
        let condition = winningCondition.lowercased()
        
        // Get current counts from local state
        let myCount = getLocalCount()
        let buddyCount = getBuddyLocalCount()
        
        guard let currentUserId = authViewModel.currentUserId else { return }
        
        // Check different winning conditions
        if condition.contains("first to reach") || condition.contains("first_to_reach_x") {
            // First to reach X number
            guard let target = goalWithProgress.goal.winningNumber else { return }
            
            let isUserWinner = myCount >= target && buddyCount < target
            
            if isUserWinner {
                print("🏆 Local winner check - User wins! (First to reach \(target))")
                isWinner = true
                showWinnerModal = true
            }
        } else if condition.contains("first to finish") || condition.contains("first_to_finish") {
            // First to finish the list (for user created list)
            if let listItems = goalWithProgress.goal.listItems {
                let myCompleted = myCount
                let buddyCompleted = buddyCount
                let isUserWinner = myCompleted >= listItems.count && buddyCompleted < listItems.count
                
                if isUserWinner {
                    print("🏆 Local winner check - User wins! (First to finish list)")
                    isWinner = true
                    showWinnerModal = true
                }
            }
        } else if condition.contains("first to complete x") || condition.contains("first_to_complete_x_amount") {
            // First to complete X amount (for daily tracker with quantity)
            guard let target = goalWithProgress.goal.winningNumber else { return }
            
            let isUserWinner = myCount >= target && buddyCount < target
            
            if isUserWinner {
                print("🏆 Local winner check - User wins! (First to complete \(target))")
                isWinner = true
                showWinnerModal = true
            }
        } else if condition.contains("first to reach x days streak") || condition.contains("first_to_reach_x_days_streak") {
            // First to reach X days streak
            guard let target = goalWithProgress.goal.winningNumber else { return }
            
            let myStreak = calculateStreak(from: myProgress?.completedDays ?? myProgressData?.completedDays ?? [])
            let buddyStreak = calculateStreak(from: buddyProgress?.completedDays ?? buddyProgressData?.completedDays ?? [])
            
            let isUserWinner = myStreak.current >= target && buddyStreak.current < target
            
            if isUserWinner {
                print("🏆 Local winner check - User wins! (First to reach \(target) day streak)")
                isWinner = true
                showWinnerModal = true
            }
        }
    }
    
    /// Get local count for current user based on goal type
    private func getLocalCount() -> Int {
        switch goalWithProgress.goal.goalType {
        case "list_tracker":
            return myProgress?.listItems?.count ?? myProgressData?.listItems?.count ?? 0
        case "list_created_by_user":
            return myProgress?.listItems?.count ?? myProgressData?.listItems?.count ?? 0
        case "daily_tracker":
            if goalWithProgress.goal.trackDailyQuantity == true {
                let total = (myProgress?.listItems ?? myProgressData?.listItems ?? []).reduce(0.0) { sum, item in
                    sum + (Double(item.title) ?? 0.0)
                }
                return Int(total)
            } else {
                return (myProgress?.completedDays ?? myProgressData?.completedDays ?? []).count
            }
        default:
            return myProgress?.listItems?.count ?? myProgressData?.listItems?.count ?? 0
        }
    }
    
    /// Get local count for buddy based on goal type
    private func getBuddyLocalCount() -> Int {
        switch goalWithProgress.goal.goalType {
        case "list_tracker":
            return buddyProgress?.listItems?.count ?? buddyProgressData?.listItems?.count ?? 0
        case "list_created_by_user":
            return buddyProgress?.listItems?.count ?? buddyProgressData?.listItems?.count ?? 0
        case "daily_tracker":
            if goalWithProgress.goal.trackDailyQuantity == true {
                let total = (buddyProgress?.listItems ?? buddyProgressData?.listItems ?? []).reduce(0.0) { sum, item in
                    sum + (Double(item.title) ?? 0.0)
                }
                return Int(total)
            } else {
                return (buddyProgress?.completedDays ?? buddyProgressData?.completedDays ?? []).count
            }
        default:
            return buddyProgress?.listItems?.count ?? buddyProgressData?.listItems?.count ?? 0
        }
    }
    
    /// Get the other person's name (buddy or creator)
    private func getOtherPersonName() -> String {
        if isCreator {
            return buddyName ?? "Buddy"
        } else {
            return creatorName
        }
    }
    
    /// Handle winner modal close - mark message as seen
    private func handleWinnerModalClose() {
        showWinnerModal = false
        
        guard let currentUserId = authViewModel.currentUserId else { return }
        
        // OPTIMISTIC UPDATE: Mark message as seen immediately (before server confirmation)
        if let currentProg = myProgress ?? myProgressData {
            myProgress = GoalProgress(
                id: currentProg.id,
                goalId: currentProg.goalId,
                userId: currentProg.userId,
                numericValue: currentProg.numericValue,
                completedDays: currentProg.completedDays,
                listItems: currentProg.listItems,
                updatedAt: currentProg.updatedAt,
                hasSeenWinnerMessage: true
            )
        }
        
        // Update goalWithProgress to reflect the change
        if isCreator {
            goalWithProgress.creatorProgress = myProgress
        } else {
            goalWithProgress.buddyProgress = myProgress
        }
        
        // Update viewModel's goals array optimistically so GoalsView shows correct filtering
        if let index = viewModel.goals.firstIndex(where: { $0.goal.id == goalWithProgress.goal.id }) {
            viewModel.goals[index] = goalWithProgress
        }
        
        // Navigate back immediately (the goal will now be in Finished section)
        dismiss()
        
        // Update server in background (don't wait for this)
        Task {
            let supabaseService = SupabaseService.shared
            try? await supabaseService.markWinnerMessageSeen(
                goalId: goalWithProgress.goal.id,
                userId: currentUserId
            )
            
            // Reload goals in background to sync with server
            await viewModel.loadGoals()
        }
    }
    
    /// Mark goal as finished (only creator can do this)
    private func markGoalAsFinished() {
        guard isCreator else { return } // Only creator can mark as finished
        
        Task {
            let supabaseService = SupabaseService.shared
            try? await supabaseService.markGoalAsFinished(goalId: goalWithProgress.goal.id)
            
            // Reload goals to update status
            await viewModel.loadGoals()
        }
    }
}

// MARK: - Quantity Input Popup
struct QuantityInputPopup: View {
    @Binding var quantityInput: String
    let unit: String?
    let onSubmit: () -> Void
    let onCancel: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Popup content - styled like native iOS alert
            VStack(spacing: 0) {
                // Title
                Text("Enter Quantity")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
                
                // Message
                if let unit = unit {
                    Text("Enter the quantity in \(unit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
                }
                
                // Text field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quantity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("", text: $quantityInput)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .focused($isTextFieldFocused)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        if let unit = unit {
                            Text(unit)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                
                // Buttons
                Divider()
                    .padding(.top, 20)
                
                HStack(spacing: 0) {
                    Button(action: {
                        onCancel()
                    }) {
                        Text("Cancel")
                            .font(.body)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    
                    Divider()
                        .frame(height: 44)
                    
                    Button(action: {
                        onSubmit()
                    }) {
                        Text("Submit")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(quantityInput.isEmpty ? .gray : .blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .disabled(quantityInput.isEmpty)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            .frame(width: 270)
        }
        .onAppear {
            // Delay focus slightly to ensure keyboard appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }
}

