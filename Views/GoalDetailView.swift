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
    @State private var dailyQuantityInput: String = ""
    @State private var creatorName: String = "Me"
    @State private var buddyName: String? = nil
    @State private var showQuantityPopup: Bool = false
    @State private var quantityInput: String = ""
    
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
    
    var visuals: [VisualType] {
        GoalVisualSelector.getVisuals(for: goalWithProgress.goal)
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    goalHeader
                    
                    // Input section (for current user - both creator and buddy can update)
                    inputSection
                    
                    // Render visuals based on goal type
                    ForEach(visuals, id: \.self) { visualType in
                        renderVisual(visualType)
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
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            myProgress = myProgressData
            buddyProgress = buddyProgressData
            
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
            
            // Load user names
            Task {
                await loadUserNames()
            }
        }
        .onChange(of: viewModel.goals) { updatedGoals in
            if let updatedGoal = updatedGoals.first(where: { $0.goal.id == goalWithProgress.goal.id }) {
                goalWithProgress = updatedGoal
                myProgress = myProgressData
                buddyProgress = buddyProgressData
                
                // If buddy exists but no progress entry yet, create an empty one locally
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
            }
        }
    }
    
    private var goalHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(goalWithProgress.goal.name)
                .font(.title)
                .fontWeight(.bold)
            
            if let goalType = goalWithProgress.goal.goalType {
                Text(getGoalTypeDisplayName(goalType))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text(goalWithProgress.goal.trackingMethod.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if goalWithProgress.goal.buddyId != nil {
                Text("With Accountability Buddy")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
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
                    onItemTap: { item in
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
                onDateTap: { dateString in
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
                Text("Tap items in the list above to mark them as complete")
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
        guard goalWithProgress.goal.trackDailyQuantity == true,
              let unit = goalWithProgress.goal.unitTracked else {
            return nil
        }
        
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
        
        return entries.isEmpty ? nil : entries.sorted(by: { $0.date < $1.date })
    }
    
    private func getBuddyDailyQuantityEntries() -> [DailyQuantityEntry]? {
        guard goalWithProgress.goal.trackDailyQuantity == true,
              let unit = goalWithProgress.goal.unitTracked else {
            return nil
        }
        
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
        
        return entries.isEmpty ? nil : entries.sorted(by: { $0.date < $1.date })
    }
    
    // MARK: - Actions
    
    private func addListItem() {
        guard !newListItem.isEmpty else { return }
        
        let newEntry = GoalListItem(title: newListItem, date: Date())
        let itemToAdd = newListItem
        newListItem = ""
        
        // Optimistic update
        var currentItems = myProgress?.listItems ?? myProgressData?.listItems ?? []
        currentItems.append(newEntry)
        
        updateMyProgress(listItems: currentItems)
        
        // Sync with server
        Task {
            await viewModel.updateGoalProgress(
                goalId: goalWithProgress.goal.id,
                listItems: currentItems
            )
            await viewModel.loadGoals()
        }
    }
    
    private func toggleListItemCompletion(_ item: String) {
        guard goalWithProgress.goal.goalType == "list_created_by_user" else { return }
        
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
        
        // Sync with server
        Task {
            await viewModel.updateGoalProgress(
                goalId: goalWithProgress.goal.id,
                listItems: currentItems
            )
            await viewModel.loadGoals()
        }
    }
    
    private func markTodayComplete() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        var days = myProgress?.completedDays ?? myProgressData?.completedDays ?? []
        if !days.contains(today) {
            days.append(today)
            updateMyProgress(completedDays: days)
            
            Task {
                await viewModel.updateGoalProgress(
                    goalId: goalWithProgress.goal.id,
                    numericValue: nil,
                    completedDays: days
                )
                await viewModel.loadGoals()
            }
        }
    }
    
    private func markTodayCompleteWithQuantity() {
        guard let quantity = Double(quantityInput), !quantityInput.isEmpty else { return }
        
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
        
        Task {
            await viewModel.updateGoalProgress(
                goalId: goalWithProgress.goal.id,
                numericValue: newTotal,
                completedDays: days,
                listItems: currentItems
            )
            await viewModel.loadGoals()
        }
    }
    
    private func toggleDayCompletion(dateString: String) {
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

