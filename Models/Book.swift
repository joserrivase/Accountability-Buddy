//
//  Book.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/8/25.
//

import Foundation

struct Book: Identifiable, Codable {
    let id: UUID
    let title: String
    let userId: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case userId = "user_id"
        case createdAt = "created_at"
    }
    
    init(id: UUID, title: String, userId: UUID, createdAt: Date) {
        self.id = id
        self.title = title
        self.userId = userId
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        userId = try container.decode(UUID.self, forKey: .userId)
        
        // Decode date from ISO8601 string
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            createdAt = date
        } else {
            // Fallback to standard ISO8601 format
            formatter.formatOptions = [.withInternetDateTime]
            createdAt = formatter.date(from: dateString) ?? Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(userId, forKey: .userId)
        
        // Encode date as ISO8601 string
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
    }
}
