//
//  BooksViewModel.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/8/25.
//

import Foundation
import SwiftUI

@MainActor
class BooksViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    var userId: UUID?
    
    var totalBookCount: Int {
        books.count
    }
    
    func setUserId(_ id: UUID) {
        userId = id
        Task {
            await fetchBooks()
        }
    }
    
    func fetchBooks() async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            books = try await supabaseService.fetchBooks(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addBook(title: String) async {
        guard let userId = userId, !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a book title"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let newBook = try await supabaseService.addBook(title: title, userId: userId)
            books.insert(newBook, at: 0) // Add to beginning of list
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteBook(at offsets: IndexSet) {
        guard let userId = userId else { return }
        
        Task {
            for index in offsets {
                let book = books[index]
                do {
                    try await supabaseService.deleteBook(bookId: book.id)
                    books.remove(at: index)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
