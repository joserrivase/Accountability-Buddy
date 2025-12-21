//
//  AuthView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/8/25.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isSignUp = false
    @State private var showingForgotPassword = false
    @State private var forgotPasswordEmail = ""
    @State private var usernameErrorMessage: String? = nil
    @State private var isCheckingUsername = false
    @State private var hasCheckedUsername = false
    @FocusState private var isUsernameFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("BuddyUp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 40)
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if isSignUp {
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isUsernameFocused)
                            .onSubmit {
                                // When user presses return or clicks out, check username
                                if !username.isEmpty {
                                    Task {
                                        await checkUsernameAvailability(username: username)
                                    }
                                }
                            }
                            .onChange(of: isUsernameFocused) { focused in
                                // When user clicks out of the field (focus lost)
                                if !focused && !username.isEmpty && !hasCheckedUsername {
                                    Task {
                                        await checkUsernameAvailability(username: username)
                                    }
                                }
                            }
                            .onChange(of: username) { newUsername in
                                // Clear previous error and reset check status when username changes
                                usernameErrorMessage = nil
                                hasCheckedUsername = false
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
                        
                        TextField("First Name", text: $firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.words)
                        
                        TextField("Last Name", text: $lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.words)
                    }
                    
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(errorMessage.contains("Account created") ? .green : .red)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        Task {
                            if isSignUp {
                                // Double-check username availability before sign-up
                                if !hasCheckedUsername && !username.isEmpty {
                                    await checkUsernameAvailability(username: username)
                                }
                                
                                // Only proceed if username is available
                                if usernameErrorMessage == nil && hasCheckedUsername {
                                    await authViewModel.signUp(email: email, password: password, username: username, firstName: firstName, lastName: lastName)
                                }
                            } else {
                                await authViewModel.signIn(email: email, password: password)
                            }
                        }
                    }) {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty || (isSignUp && (username.isEmpty || firstName.isEmpty || lastName.isEmpty || usernameErrorMessage != nil || isCheckingUsername || (!username.isEmpty && !hasCheckedUsername))))
                    
                    // Forgot Password button (only show on sign in)
                    if !isSignUp {
                        Button(action: {
                            showingForgotPassword = true
                            forgotPasswordEmail = email // Pre-fill with current email if available
                        }) {
                            Text("Forgot Password?")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: {
                        isSignUp.toggle()
                        authViewModel.errorMessage = nil
                        // Clear form fields when switching
                        if !isSignUp {
                            username = ""
                            firstName = ""
                            lastName = ""
                            usernameErrorMessage = nil
                            hasCheckedUsername = false
                        }
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView(
                    email: $forgotPasswordEmail,
                    isPresented: $showingForgotPassword,
                    authViewModel: authViewModel
                )
            }
        }
    }
    
    private func checkUsernameAvailability(username: String) async {
        guard !username.isEmpty else {
            usernameErrorMessage = nil
            isCheckingUsername = false
            hasCheckedUsername = false
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

// Forgot Password View
struct ForgotPasswordView: View {
    @Binding var email: String
    @Binding var isPresented: Bool
    @ObservedObject var authViewModel: AuthViewModel
    @State private var successMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("Enter your email address and we'll send you instructions to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    if let successMessage = successMessage {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let errorMessage = authViewModel.errorMessage, successMessage == nil {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        Task {
                            await authViewModel.resetPassword(email: email)
                            if authViewModel.errorMessage?.contains("sent") == true {
                                successMessage = authViewModel.errorMessage
                                authViewModel.errorMessage = nil
                                // Auto-dismiss after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    isPresented = false
                                }
                            }
                        }
                    }) {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text("Send Reset Email")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(authViewModel.isLoading || email.isEmpty)
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
