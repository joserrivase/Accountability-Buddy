//
//  AddBookView.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/8/25.
//

import SwiftUI

struct AddBookView: View {
    @ObservedObject var viewModel: BooksViewModel
    @Environment(\.dismiss) var dismiss
    @State private var bookTitle = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Title")) {
                    TextField("Enter book title", text: $bookTitle)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Add Book")
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
                            await viewModel.addBook(title: bookTitle)
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(bookTitle.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
                }
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
        }
    }
}
