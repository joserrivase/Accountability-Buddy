//
//  QuestionViews.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI
import UIKit

// MARK: - Goal Name and Description Question View

struct GoalNameAndDescriptionQuestionView: View {
    let question: Question
    @Binding var answer: Any?
    @ObservedObject var flowEngine: GoalQuestionnaireFlowEngine
    @State private var goalName: String = ""
    @State private var goalDescription: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Goal Name Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Goal Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField(question.placeholder ?? "Enter goal name", text: $goalName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled()
                    .onChange(of: goalName) { newValue in
                        // Update both the answer and flowEngine
                        flowEngine.answers.goalName = newValue.isEmpty ? nil : newValue
                        // Store as tuple to maintain compatibility with answer binding
                        answer = (newValue, goalDescription)
                    }
            }
            
            // Goal Description Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Description (Optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextEditor(text: $goalDescription)
                    .frame(minHeight: 80)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled()
                    .onChange(of: goalDescription) { newValue in
                        // Update both the answer and flowEngine
                        flowEngine.answers.goalDescription = newValue.isEmpty ? nil : newValue
                        // Store as tuple to maintain compatibility with answer binding
                        answer = (goalName, newValue)
                    }
            }
        }
        .onAppear {
            // Load existing values if available
            if let existingName = flowEngine.answers.goalName {
                goalName = existingName
            }
            if let existingDescription = flowEngine.answers.goalDescription {
                goalDescription = existingDescription
            }
            // Initialize answer binding
            answer = (goalName, goalDescription)
        }
    }
}

// MARK: - Text Input Question View

struct TextInputQuestionView: View {
    let question: Question
    @Binding var answer: Any?
    @State private var text: String = ""
    
    var body: some View {
        // Use TextEditor for winners prize (taller), TextField for others
        if question.id == .winnersPrize {
            TextEditor(text: $text)
                .frame(minHeight: 100)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .onChange(of: text) { newValue in
                    answer = newValue
                }
                .onAppear {
                    if let existingAnswer = answer as? String {
                        text = existingAnswer
                    }
                }
        } else {
            TextField(question.placeholder ?? "Enter your answer", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization((question.id == .goalName || question.id == .taskBeingTracked) ? .sentences : .never)
                .autocorrectionDisabled()
                .autocapitalization((question.id == .goalName || question.id == .taskBeingTracked) ? .sentences : .none)
                .onChange(of: text) { newValue in
                    answer = newValue
                }
                .onAppear {
                    if let existingAnswer = answer as? String {
                        text = existingAnswer
                    }
                }
        }
    }
}

// MARK: - Multiple Choice Question View

struct MultipleChoiceQuestionView: View {
    let question: Question
    @Binding var answer: Any?
    @ObservedObject var flowEngine: GoalQuestionnaireFlowEngine
    @State private var selectedOptionId: String?
    
    var options: [QuestionOption] {
        if question.id == .winningCondition {
            // Use dynamic options for winning condition
            return flowEngine.getWinningConditionOptions()
        } else {
            return question.options ?? []
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(options) { option in
                Button(action: {
                    selectedOptionId = option.id
                    answer = option.id
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(option.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedOptionId == option.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let description = option.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding()
                    .background(selectedOptionId == option.id ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedOptionId == option.id ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .onAppear {
            if let existingAnswer = answer as? String {
                selectedOptionId = existingAnswer
            }
        }
    }
}

// MARK: - Buddy Selection Question View

struct BuddySelectionQuestionView: View {
    let question: Question
    @Binding var answer: Any?
    @ObservedObject var friendsViewModel: FriendsViewModel
    @State private var selectedBuddy: UUID?
    @State private var isSolo: Bool = false
    @State private var showingBuddyPicker = false
    @State private var showingShareSheet = false
    
    // TODO: Replace this with your actual App Store link when available
    // For now, use a placeholder or your website URL
    private let appStoreURL = "https://apps.apple.com/us/app/buddyup-accountability-app/id6756550977" // Replace with your actual App Store link
    
    var body: some View {
        VStack(spacing: 16) {
            // Solo option
            Button(action: {
                isSolo = true
                selectedBuddy = nil
                answer = (nil as UUID?, true)
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Go Solo")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Complete this goal on your own")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if isSolo {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(isSolo ? Color.blue.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSolo ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Add buddy option
            Button(action: {
                showingBuddyPicker = true
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add Accountability Buddy")
                            .font(.headline)
                            .foregroundColor(.primary)
                        if let buddyId = selectedBuddy,
                           let buddy = friendsViewModel.friends.first(where: { $0.userId == buddyId }) {
                            Text(buddy.displayName != "User" ? buddy.displayName : (buddy.username ?? "Selected"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Choose a friend to join your goal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    if selectedBuddy != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(selectedBuddy != nil ? Color.blue.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedBuddy != nil ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Invite Friends to App Card
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("Invite Friends to App")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Text("Invite your friends to join you in your goals")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    showingShareSheet = true
                }) {
                    Text("Send Invite")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .sheet(isPresented: $showingBuddyPicker) {
            QuestionnaireBuddyPickerView(
                selectedBuddy: $selectedBuddy,
                friendsViewModel: friendsViewModel,
                onSelect: { buddyId in
                    selectedBuddy = buddyId
                    isSolo = false
                    answer = (buddyId, false)
                }
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheetContainer(activityItems: [appStoreURL])
                .presentationDetents([.medium])
        }
        .onAppear {
            if let existingAnswer = answer as? (UUID?, Bool) {
                selectedBuddy = existingAnswer.0
                isSolo = existingAnswer.1
            }
        }
    }
}

// MARK: - List Input Question View

struct ListInputQuestionView: View {
    let question: Question
    @Binding var answer: Any?
    @State private var items: [String] = []
    @State private var newItem: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Add item input
            HStack {
                TextField("Enter item", text: $newItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if !newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        items.append(newItem)
                        newItem = ""
                        answer = items
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // List of items
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        HStack {
                            Text("\(index + 1). \(item)")
                                .font(.body)
                            Spacer()
                            Button(action: {
                                items.remove(at: index)
                                answer = items
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text("No items added yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .onAppear {
            if let existingItems = answer as? [String] {
                items = existingItems
            }
        }
    }
}

// MARK: - Yes/No Question View

struct YesNoQuestionView: View {
    let question: Question
    @Binding var answer: Any?
    @State private var selectedValue: Bool?
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                selectedValue = true
                answer = true
            }) {
                Text("Yes")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedValue == true ? Color.blue : Color(.systemGray5))
                    .foregroundColor(selectedValue == true ? .white : .primary)
                    .cornerRadius(10)
            }
            
            Button(action: {
                selectedValue = false
                answer = false
            }) {
                Text("No")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedValue == false ? Color.blue : Color(.systemGray5))
                    .foregroundColor(selectedValue == false ? .white : .primary)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            // Reset state when question appears to prevent state from previous question
            selectedValue = nil
            
            // Only restore if there's an existing answer for THIS specific question
            if let existingAnswer = answer as? Bool {
                selectedValue = existingAnswer
            } else {
                // Explicitly clear the answer binding to ensure it's nil
                answer = nil
            }
        }
        .id(question.id.rawValue) // Force view to reset when question ID changes
    }
}

// MARK: - Unit Selection Question View

struct UnitSelectionQuestionView: View {
    let question: Question
    @Binding var answer: Any?
    @State private var selectedUnit: String?
    @State private var customUnit: String = ""
    @State private var showingCustomInput = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Standard units
            ForEach(TrackingUnit.allCases, id: \.self) { unit in
                Button(action: {
                    if unit == .other {
                        showingCustomInput = true
                    } else {
                        selectedUnit = unit.rawValue
                        answer = unit.rawValue
                        showingCustomInput = false
                    }
                }) {
                    HStack {
                        Text(unit.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedUnit == unit.rawValue {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(selectedUnit == unit.rawValue ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedUnit == unit.rawValue ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Custom unit input
            if showingCustomInput {
                TextField("Enter custom unit", text: $customUnit)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: customUnit) { newValue in
                        if !newValue.isEmpty {
                            selectedUnit = newValue
                            answer = newValue
                        }
                    }
            }
        }
        .onAppear {
            if let existingAnswer = answer as? String {
                selectedUnit = existingAnswer
                if !TrackingUnit.allCases.contains(where: { $0.rawValue == existingAnswer }) {
                    customUnit = existingAnswer
                    showingCustomInput = true
                }
            }
        }
    }
}

// MARK: - Date Input Question View

struct DateInputQuestionView: View {
    let question: Question
    @Binding var answer: Any?
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        DatePicker(
            "Select date",
            selection: $selectedDate,
            displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .onChange(of: selectedDate) { newValue in
            answer = newValue
        }
        .onAppear {
            if let existingDate = answer as? Date {
                selectedDate = existingDate
            } else {
                // Default to 30 days from now
                selectedDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
                answer = selectedDate
            }
        }
    }
}

// MARK: - Number Input Question View

struct NumberInputQuestionView: View {
    let question: Question
    @Binding var answer: Any?
    @State private var numberText: String = ""
    
    var body: some View {
        TextField(question.placeholder ?? "Enter number", text: $numberText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.numberPad)
            .onChange(of: numberText) { newValue in
                if let number = Int(newValue) {
                    answer = number
                } else {
                    answer = nil
                }
            }
            .onAppear {
                if let existingNumber = answer as? Int {
                    numberText = String(existingNumber)
                }
            }
    }
}

// MARK: - Buddy Picker View (for questionnaire)

struct QuestionnaireBuddyPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedBuddy: UUID?
    @ObservedObject var friendsViewModel: FriendsViewModel
    let onSelect: (UUID) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(friendsViewModel.friends) { friend in
                    Button(action: {
                        selectedBuddy = friend.userId
                        onSelect(friend.userId)
                        dismiss()
                    }) {
                        HStack {
                        if let imageUrlString = friend.profileImageUrl,
                           let imageUrl = URL(string: imageUrlString) {
                            RemoteImageView(url: imageUrl) {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .overlay(ProgressView())
                            }
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                        }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(friend.displayName != "User" ? friend.displayName : "No name")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                if let username = friend.username {
                                    Text("@\(username)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedBuddy == friend.userId {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Buddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// Container view to enable presentation detents
struct ShareSheetContainer: View {
    let activityItems: [Any]
    
    var body: some View {
        ShareSheet(activityItems: activityItems)
            .ignoresSafeArea()
    }
}

