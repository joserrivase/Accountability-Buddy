//
//  AddGoalView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI

struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: GoalsViewModel
    @ObservedObject var friendsViewModel: FriendsViewModel
    
    @State private var goalName = ""
    @State private var selectedTrackingMethod: TrackingMethod = .inputNumbers
    @State private var selectedBuddy: UserProfile?
    @State private var showingBuddyPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Goal Name", text: $goalName)
                        .textInputAutocapitalization(.words)
                }
                
                Section(header: Text("Tracking Method")) {
                    Picker("Tracking Method", selection: $selectedTrackingMethod) {
                        ForEach(TrackingMethod.allCases, id: \.self) { method in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(method.displayName)
                                    .font(.body)
                                Text(method.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(method)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Accountability Buddy")) {
                    Button(action: {
                        showingBuddyPicker = true
                    }) {
                        HStack {
                            Text("Select Buddy")
                                .foregroundColor(.primary)
                            Spacer()
                            if let buddy = selectedBuddy {
                                Text(buddy.name ?? buddy.username ?? "Selected")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Optional")
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    if let buddy = selectedBuddy {
                        HStack {
                            if let imageUrlString = buddy.profileImageUrl,
                               let imageUrl = URL(string: imageUrlString) {
                                AsyncImage(url: imageUrl) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 30, height: 30)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure:
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(buddy.name ?? "No name")
                                    .font(.subheadline)
                                if let username = buddy.username {
                                    Text("@\(username)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                selectedBuddy = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            // Create empty questionnaire answers for legacy goal creation
                            let emptyAnswers = GoalQuestionnaireAnswers()
                            await viewModel.createGoal(
                                name: goalName,
                                trackingMethod: selectedTrackingMethod,
                                buddyId: selectedBuddy?.userId,
                                questionnaireAnswers: emptyAnswers
                            )
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(goalName.isEmpty || viewModel.isLoading)
                }
            }
            .sheet(isPresented: $showingBuddyPicker) {
                BuddyPickerView(selectedBuddy: $selectedBuddy, friendsViewModel: friendsViewModel)
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
                Task {
                    await friendsViewModel.loadFriends()
                }
            }
        }
    }
}

// Buddy Picker View
struct BuddyPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedBuddy: UserProfile?
    @ObservedObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    selectedBuddy = nil
                    dismiss()
                }) {
                    HStack {
                        Text("No Buddy (Solo Goal)")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedBuddy == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ForEach(friendsViewModel.friends) { friend in
                    Button(action: {
                        selectedBuddy = friend
                        dismiss()
                    }) {
                        HStack {
                            if let imageUrlString = friend.profileImageUrl,
                               let imageUrl = URL(string: imageUrlString) {
                                AsyncImage(url: imageUrl) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 40, height: 40)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure:
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(friend.name ?? "No name")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                if let username = friend.username {
                                    Text("@\(username)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedBuddy?.userId == friend.userId {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Buddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

