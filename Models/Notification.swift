//
//  Notification.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import Foundation

enum NotificationType: String, Codable {
    case friendRequest = "friend_request"
    case goalUpdate = "goal_update"
}

struct AppNotification: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let type: NotificationType
    let title: String
    let message: String
    let relatedUserId: UUID? // For friend requests
    let relatedGoalId: UUID? // For goal updates
    var isRead: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case title
        case message
        case relatedUserId = "related_user_id"
        case relatedGoalId = "related_goal_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
    
    init(id: UUID, userId: UUID, type: NotificationType, title: String, message: String, relatedUserId: UUID? = nil, relatedGoalId: UUID? = nil, isRead: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.relatedUserId = relatedUserId
        self.relatedGoalId = relatedGoalId
        self.isRead = isRead
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        type = try container.decode(NotificationType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        relatedUserId = try container.decodeIfPresent(UUID.self, forKey: .relatedUserId)
        relatedGoalId = try container.decodeIfPresent(UUID.self, forKey: .relatedGoalId)
        isRead = try container.decode(Bool.self, forKey: .isRead)
        
        // Decode date from ISO8601 string
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        if let date = dateFormatter.date(from: createdAtString) {
            createdAt = date
        } else {
            dateFormatter.formatOptions = [.withInternetDateTime]
            createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(relatedUserId, forKey: .relatedUserId)
        try container.encodeIfPresent(relatedGoalId, forKey: .relatedGoalId)
        try container.encode(isRead, forKey: .isRead)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
    }
}

