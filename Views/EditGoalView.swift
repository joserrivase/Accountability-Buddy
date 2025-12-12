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
    @State private var editingField: EditingField? = nil
    
    enum EditingField {
        case goalName
        case taskBeingTracked
        case listItems
        case keepStreak
        case trackDailyQuantity
        case unitTracked
        case challengeOrFriendly
        case winningCondition
        case winningNumber
        case endDate
        case winnersPrize
    }
    
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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Goal Summary with Edit Buttons
                    VStack(alignment: .leading, spacing: 16) {
                        // Goal Name - Editable
                        EditableReviewSection(
                            title: "Goal Name",
                            value: editedAnswers.goalName ?? "Not set",
                            isEditing: editingField == .goalName
                        ) {
                            editingField = .goalName
                        } onEdit: { newValue in
                            editedAnswers.goalName = newValue.isEmpty ? nil : newValue
                            editingField = nil
                        }
                        
                        // Goal Type - Not Editable
                        ReviewSection(title: "Goal Type") {
                            Text(getGoalTypeDisplayName())
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Buddy - Not Editable
                        ReviewSection(title: "Accountability") {
                            if goal.buddyId == nil {
                                Text("Solo Goal")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("With Accountability Buddy")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Goal-specific editable fields
                        if let task = editedAnswers.taskBeingTracked {
                            EditableReviewSection(
                                title: "Task Being Tracked",
                                value: task,
                                isEditing: editingField == .taskBeingTracked
                            ) {
                                editingField = .taskBeingTracked
                            } onEdit: { newValue in
                                editedAnswers.taskBeingTracked = newValue.isEmpty ? nil : newValue
                                editingField = nil
                            }
                        }
                        
                        if let items = editedAnswers.listItems, !items.isEmpty {
                            EditableListSection(
                                title: "List Items",
                                items: items,
                                isEditing: editingField == .listItems
                            ) {
                                editingField = .listItems
                            } onEdit: { newItems in
                                editedAnswers.listItems = newItems
                                editingField = nil
                            }
                        }
                        
                        if goal.goalType == "daily_tracker" {
                            if let keepStreak = editedAnswers.keepStreak {
                                EditableYesNoSection(
                                    title: "Keep Streak",
                                    value: keepStreak,
                                    isEditing: editingField == .keepStreak
                                ) {
                                    editingField = .keepStreak
                                } onEdit: { newValue in
                                    editedAnswers.keepStreak = newValue
                                    editingField = nil
                                }
                            }
                            
                            if let trackQuantity = editedAnswers.trackDailyQuantity {
                                EditableYesNoSection(
                                    title: "Track Daily Quantity",
                                    value: trackQuantity,
                                    isEditing: editingField == .trackDailyQuantity
                                ) {
                                    editingField = .trackDailyQuantity
                                } onEdit: { newValue in
                                    editedAnswers.trackDailyQuantity = newValue
                                    editingField = nil
                                }
                                
                                if trackQuantity, let unit = editedAnswers.unitTracked {
                                    EditableReviewSection(
                                        title: "Unit Tracked",
                                        value: unit,
                                        isEditing: editingField == .unitTracked
                                    ) {
                                        editingField = .unitTracked
                                    } onEdit: { newValue in
                                        editedAnswers.unitTracked = newValue.isEmpty ? nil : newValue
                                        editingField = nil
                                    }
                                }
                            }
                        }
                        
                        // Mode - Editable
                        if let mode = editedAnswers.challengeOrFriendly {
                            EditableModeSection(
                                title: "Mode",
                                value: mode,
                                isEditing: editingField == .challengeOrFriendly
                            ) {
                                editingField = .challengeOrFriendly
                            } onEdit: { newValue in
                                editedAnswers.challengeOrFriendly = newValue
                                editingField = nil
                            }
                        }
                        
                        // Challenge details - Editable
                        if editedAnswers.isChallenge {
                            if let winningCondition = editedAnswers.winningCondition {
                                EditableReviewSection(
                                    title: "Challenge Objective",
                                    value: winningCondition,
                                    isEditing: editingField == .winningCondition
                                ) {
                                    editingField = .winningCondition
                                } onEdit: { newValue in
                                    editedAnswers.winningCondition = newValue.isEmpty ? nil : newValue
                                    editingField = nil
                                }
                            }
                            
                            if let winningNumber = editedAnswers.winningNumber {
                                EditableNumberSection(
                                    title: "Target Number",
                                    value: winningNumber,
                                    isEditing: editingField == .winningNumber
                                ) {
                                    editingField = .winningNumber
                                } onEdit: { newValue in
                                    editedAnswers.winningNumber = newValue
                                    editingField = nil
                                }
                            }
                            
                            if let endDate = editedAnswers.endDate {
                                EditableDateSection(
                                    title: "End Date",
                                    value: endDate,
                                    isEditing: editingField == .endDate
                                ) {
                                    editingField = .endDate
                                } onEdit: { newValue in
                                    editedAnswers.endDate = newValue
                                    editingField = nil
                                }
                            }
                            
                            if let prize = editedAnswers.winnersPrize {
                                EditableReviewSection(
                                    title: "Challenge Stakes",
                                    value: prize,
                                    isEditing: editingField == .winnersPrize,
                                    isMultiLine: true
                                ) {
                                    editingField = .winnersPrize
                                } onEdit: { newValue in
                                    editedAnswers.winnersPrize = newValue.isEmpty ? nil : newValue
                                    editingField = nil
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // Save button
                    Button(action: {
                        Task {
                            await saveGoal()
                        }
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isSaving ? "Saving..." : "Save Changes")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isSaving ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isSaving)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.vertical)
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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

            // Try to grab the freshly reloaded goal from the viewModel for immediate UI update
            await MainActor.run {
                if let refreshedGoal = viewModel.goals.first(where: { $0.goal.id == goal.id })?.goal {
                    onSave?(refreshedGoal)
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

// MARK: - Editable Review Section Component

struct EditableReviewSection: View {
    let title: String
    let value: String
    var isEditing: Bool = false
    var isMultiLine: Bool = false
    let onEditTap: () -> Void
    let onEdit: (String) -> Void
    
    @State private var editValue: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            if isEditing {
                if isMultiLine {
                    TextEditor(text: $editValue)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                        .focused($isFocused)
                        .onAppear {
                            editValue = value
                            isFocused = true
                        }
                } else {
                    TextField("", text: $editValue)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isFocused)
                        .onAppear {
                            editValue = value
                            isFocused = true
                        }
                }
                
                HStack {
                    Button("Cancel") {
                        isFocused = false
                        onEdit(value) // Reset to original value
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Save") {
                        isFocused = false
                        onEdit(editValue)
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            } else {
                HStack {
                    Text(value)
                        .font(.body)
                    Spacer()
                    Button(action: onEditTap) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

// MARK: - Editable Yes/No Section

struct EditableYesNoSection: View {
    let title: String
    let value: Bool
    var isEditing: Bool = false
    let onEditTap: () -> Void
    let onEdit: (Bool) -> Void
    
    @State private var editValue: Bool
    
    init(title: String, value: Bool, isEditing: Bool, onEditTap: @escaping () -> Void, onEdit: @escaping (Bool) -> Void) {
        self.title = title
        self.value = value
        self.isEditing = isEditing
        self.onEditTap = onEditTap
        self.onEdit = onEdit
        _editValue = State(initialValue: value)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            if isEditing {
                Picker("", selection: $editValue) {
                    Text("Yes").tag(true)
                    Text("No").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                HStack {
                    Button("Cancel") {
                        editValue = value
                        onEdit(value)
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Save") {
                        onEdit(editValue)
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            } else {
                HStack {
                    Text(value ? "Yes" : "No")
                        .font(.body)
                    Spacer()
                    Button(action: onEditTap) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

// MARK: - Editable Mode Section

struct EditableModeSection: View {
    let title: String
    let value: String
    var isEditing: Bool = false
    let onEditTap: () -> Void
    let onEdit: (String) -> Void
    
    @State private var editValue: String
    
    init(title: String, value: String, isEditing: Bool, onEditTap: @escaping () -> Void, onEdit: @escaping (String) -> Void) {
        self.title = title
        self.value = value
        self.isEditing = isEditing
        self.onEditTap = onEditTap
        self.onEdit = onEdit
        _editValue = State(initialValue: value)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            if isEditing {
                Picker("", selection: $editValue) {
                    Text("Challenge").tag("challenge")
                    Text("Friendly").tag("friendly")
                }
                .pickerStyle(SegmentedPickerStyle())
                
                HStack {
                    Button("Cancel") {
                        editValue = value
                        onEdit(value)
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Save") {
                        onEdit(editValue)
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            } else {
                HStack {
                    Text(value == "challenge" ? "Challenge" : "Friendly")
                        .font(.body)
                    Spacer()
                    Button(action: onEditTap) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

// MARK: - Editable Number Section

struct EditableNumberSection: View {
    let title: String
    let value: Int
    var isEditing: Bool = false
    let onEditTap: () -> Void
    let onEdit: (Int?) -> Void
    
    @State private var editValue: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            if isEditing {
                TextField("", text: $editValue)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isFocused)
                    .onAppear {
                        editValue = "\(value)"
                        isFocused = true
                    }
                
                HStack {
                    Button("Cancel") {
                        isFocused = false
                        onEdit(value) // Reset to original value
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Save") {
                        isFocused = false
                        let newValue = Int(editValue)
                        onEdit(newValue)
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            } else {
                HStack {
                    Text("\(value)")
                        .font(.body)
                    Spacer()
                    Button(action: onEditTap) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

// MARK: - Editable Date Section

struct EditableDateSection: View {
    let title: String
    let value: Date
    var isEditing: Bool = false
    let onEditTap: () -> Void
    let onEdit: (Date?) -> Void
    
    @State private var editValue: Date
    
    init(title: String, value: Date, isEditing: Bool, onEditTap: @escaping () -> Void, onEdit: @escaping (Date?) -> Void) {
        self.title = title
        self.value = value
        self.isEditing = isEditing
        self.onEditTap = onEditTap
        self.onEdit = onEdit
        _editValue = State(initialValue: value)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            if isEditing {
                DatePicker("", selection: $editValue, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                
                HStack {
                    Button("Cancel") {
                        editValue = value
                        onEdit(value)
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Save") {
                        onEdit(editValue)
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            } else {
                HStack {
                    Text(value, style: .date)
                        .font(.body)
                    Spacer()
                    Button(action: onEditTap) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

// MARK: - Editable List Section

struct EditableListSection: View {
    let title: String
    let items: [String]
    var isEditing: Bool = false
    let onEditTap: () -> Void
    let onEdit: ([String]) -> Void
    
    @State private var editItems: [String] = []
    @State private var newItem: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(editItems.enumerated()), id: \.offset) { index, item in
                        HStack {
                            TextField("Item", text: Binding(
                                get: { item },
                                set: { newValue in
                                    editItems[index] = newValue
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: {
                                editItems.remove(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("New item", text: $newItem)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Add") {
                            if !newItem.isEmpty {
                                editItems.append(newItem)
                                newItem = ""
                            }
                        }
                    }
                }
                
                HStack {
                    Button("Cancel") {
                        editItems = items
                        onEdit(items)
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Save") {
                        onEdit(editItems)
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        Text("\(index + 1). \(item)")
                            .font(.caption)
                    }
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            editItems = items
                            onEditTap()
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
}
