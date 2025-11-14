//
//  BooksView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/8/25.
//

import SwiftUI

struct BooksView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = BooksViewModel()
    @State private var showingAddBook = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Total Book Count Card
                VStack(spacing: 8) {
                    Text("Total Books Finished")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.totalBookCount)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top)
                
                // Books List
                if viewModel.isLoading && viewModel.books.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.books.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No books yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Tap the + button to add your first finished book")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.books) { book in
                            HStack {
                                Image(systemName: "book.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text(book.title)
                                    .font(.body)
                                Spacer()
                                Text(book.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: viewModel.deleteBook)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("My Books")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddBook = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookView(viewModel: viewModel)
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
                if let userId = authViewModel.currentUserId {
                    viewModel.setUserId(userId)
                }
            }
        }
    }
}
