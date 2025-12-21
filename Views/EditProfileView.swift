//
//  EditProfileView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI
import PhotosUI
import Photos

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var username: String = ""
    @State private var originalUsername: String = "" // Store original username to compare
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingPermissionAlert = false
    @State private var photoLibraryStatus: PHAuthorizationStatus = .notDetermined
    @State private var usernameErrorMessage: String? = nil
    @State private var isCheckingUsername = false
    @State private var hasCheckedUsername = false
    @FocusState private var isUsernameFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Image")) {
                    HStack {
                        Spacer()
                        
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                        } else if let imageUrlString = viewModel.profile?.profileImageUrl,
                                  let imageUrl = URL(string: imageUrlString) {
                            AsyncImage(url: imageUrl) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 120, height: 120)
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
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .foregroundColor(.gray)
                                .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Text("Select Photo")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .onChange(of: selectedPhotoItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                await MainActor.run {
                                    selectedImage = image
                                }
                            }
                        }
                    }
                    
                    // Show message if photo library access is denied
                    if photoLibraryStatus == .denied || photoLibraryStatus == .restricted {
                        Text("Photo library access is required. Please enable it in Settings.")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
                
                Section(header: Text("Personal Information")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Username")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isUsernameFocused)
                            .onSubmit {
                                // When user presses return or clicks out, check username if it changed
                                if !username.isEmpty && username != originalUsername {
                                    Task {
                                        await checkUsernameAvailability(username: username)
                                    }
                                }
                            }
                            .onChange(of: isUsernameFocused) { focused in
                                // When user clicks out of the field (focus lost)
                                if !focused && !username.isEmpty && username != originalUsername && !hasCheckedUsername {
                                    Task {
                                        await checkUsernameAvailability(username: username)
                                    }
                                }
                            }
                            .onChange(of: username) { newUsername in
                                // Clear previous error and reset check status when username changes
                                if newUsername == originalUsername {
                                    // Username is back to original, clear error
                                    usernameErrorMessage = nil
                                    hasCheckedUsername = true
                                } else {
                                    // Username changed, need to check again
                                    usernameErrorMessage = nil
                                    hasCheckedUsername = false
                                }
                            }
                        
                        if let usernameError = usernameErrorMessage {
                            Text(usernameError)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        if isCheckingUsername {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Checking username...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("First Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("First Name", text: $firstName)
                            .textInputAutocapitalization(.words)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Last Name", text: $lastName)
                            .textInputAutocapitalization(.words)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Profile")
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
                            // Double-check username availability before saving if username changed
                            if username != originalUsername && !username.isEmpty && !hasCheckedUsername {
                                await checkUsernameAvailability(username: username)
                            }
                            
                            // Only proceed if username is available (or unchanged)
                            if username == originalUsername || usernameErrorMessage == nil {
                                await saveProfile()
                            }
                        }
                    }
                    .disabled(viewModel.isSaving || 
                             (username != originalUsername && (usernameErrorMessage != nil || isCheckingUsername || (!username.isEmpty && !hasCheckedUsername))))
                }
            }
            .onAppear {
                username = viewModel.profile?.username ?? ""
                originalUsername = username // Store original username for comparison
                // Use firstName and lastName directly from profile, fallback to splitting name if needed
                if let profileFirstName = viewModel.profile?.firstName, !profileFirstName.isEmpty {
                    firstName = profileFirstName
                } else if let fullName = viewModel.profile?.name, !fullName.isEmpty {
                    // Fallback: split existing name for backward compatibility
                    let nameComponents = fullName.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
                    firstName = nameComponents[0]
                    lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : ""
                } else {
                    firstName = ""
                }
                
                if let profileLastName = viewModel.profile?.lastName, !profileLastName.isEmpty {
                    lastName = profileLastName
                } else if firstName.isEmpty && lastName.isEmpty {
                    lastName = ""
                }
                
                checkPhotoLibraryPermission()
            }
            .alert("Photo Library Access Required", isPresented: $showingPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } message: {
                Text("Please allow access to your photo library in Settings to select a profile picture.")
            }
        }
    }
    
    private func checkPhotoLibraryPermission() {
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        // If permission is not determined, request it
        if photoLibraryStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    photoLibraryStatus = status
                    // If user denies, show alert to guide them to settings
                    if status == .denied || status == .restricted {
                        showingPermissionAlert = true
                    }
                }
            }
        } else if photoLibraryStatus == .denied || photoLibraryStatus == .restricted {
            // Permission was previously denied, show alert when view appears
            showingPermissionAlert = true
        }
    }
    
    private func saveProfile() async {
        var imageUrl: String? = viewModel.profile?.profileImageUrl
        
        // Upload image if a new one was selected
        if let selectedImage = selectedImage,
           let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
            if let uploadedUrl = await viewModel.uploadProfileImage(imageData: imageData) {
                imageUrl = uploadedUrl
            } else {
                return // Error handling is done in viewModel
            }
        }
        
        // Update profile with firstName and lastName directly
        await viewModel.updateProfile(
            username: username.isEmpty ? nil : username,
            firstName: firstName.isEmpty ? nil : firstName,
            lastName: lastName.isEmpty ? nil : lastName,
            profileImageUrl: imageUrl
        )
        
        // Only dismiss if there's no error
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }
    
    private func checkUsernameAvailability(username: String) async {
        guard !username.isEmpty else {
            usernameErrorMessage = nil
            isCheckingUsername = false
            hasCheckedUsername = false
            return
        }
        
        // Don't check if username is the same as original
        if username == originalUsername {
            usernameErrorMessage = nil
            isCheckingUsername = false
            hasCheckedUsername = true
            return
        }
        
        isCheckingUsername = true
        usernameErrorMessage = nil
        hasCheckedUsername = false
        
        let isAvailable = await SupabaseService.shared.checkUsernameAvailability(username: username)
        
        await MainActor.run {
            isCheckingUsername = false
            hasCheckedUsername = true
            if !isAvailable {
                usernameErrorMessage = "This username is already taken"
            } else {
                usernameErrorMessage = nil
            }
        }
    }
}

