//
//  EditProfileView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var username: String = ""
    @State private var name: String = ""
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    
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
                                selectedImage = image
                            }
                        }
                    }
                }
                
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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
                            await saveProfile()
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .onAppear {
                username = viewModel.profile?.username ?? ""
                name = viewModel.profile?.name ?? ""
            }
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
        
        // Update profile
        await viewModel.updateProfile(
            username: username.isEmpty ? nil : username,
            name: name.isEmpty ? nil : name,
            profileImageUrl: imageUrl
        )
        
        // Only dismiss if there's no error
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }
}

