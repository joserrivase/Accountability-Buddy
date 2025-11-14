//
//  Friendship.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import Foundation

struct Friendship: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let friendId: UUID
    let status: FriendshipStatus
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendId = "friend_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    enum FriendshipStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case blocked = "blocked"
    }
    
    init(id: UUID, userId: UUID, friendId: UUID, status: FriendshipStatus, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.friendId = friendId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        friendId = try container.decode(UUID.self, forKey: .friendId)
        status = try container.decode(FriendshipStatus.self, forKey: .status)
        
        // Decode dates from ISO8601 strings
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        if let date = dateFormatter.date(from: createdAtString) {
            createdAt = date
        } else {
            dateFormatter.formatOptions = [.withInternetDateTime]
            createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        }
        
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        if let date = dateFormatter.date(from: updatedAtString) {
            updatedAt = date
        } else {
            dateFormatter.formatOptions = [.withInternetDateTime]
            updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(friendId, forKey: .friendId)
        try container.encode(status, forKey: .status)
        
        // Encode dates as ISO8601 strings
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
    }
}

// Extended profile with friend information
struct UserProfile: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var username: String?
    var name: String?
    var profileImageUrl: String?
    let createdAt: Date
    let updatedAt: Date
    var friendshipId: UUID?
    var friendshipStatus: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case name
        case profileImageUrl = "profile_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case friendshipId = "friendship_id"
        case friendshipStatus = "friendship_status"
    }
    
    init(id: UUID, userId: UUID, username: String? = nil, name: String? = nil, profileImageUrl: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date(), friendshipId: UUID? = nil, friendshipStatus: String? = nil) {
        self.id = id
        self.userId = userId
        self.username = username
        self.name = name
        self.profileImageUrl = profileImageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.friendshipId = friendshipId
        self.friendshipStatus = friendshipStatus
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        // Decode username and name, handling both null and empty string from database
        // decodeIfPresent returns String?, so we handle the optional
        if let usernameValue = try container.decodeIfPresent(String.self, forKey: .username) {
            username = usernameValue.isEmpty ? nil : usernameValue
        } else {
            username = nil
        }
        
        if let nameValue = try container.decodeIfPresent(String.self, forKey: .name) {
            name = nameValue.isEmpty ? nil : nameValue
        } else {
            name = nil
        }
        
        if let imageUrlValue = try container.decodeIfPresent(String.self, forKey: .profileImageUrl) {
            profileImageUrl = imageUrlValue.isEmpty ? nil : imageUrlValue
        } else {
            profileImageUrl = nil
        }
        
        friendshipId = try container.decodeIfPresent(UUID.self, forKey: .friendshipId)
        friendshipStatus = try container.decodeIfPresent(String.self, forKey: .friendshipStatus)
        
        // Decode dates from ISO8601 strings
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        if let date = dateFormatter.date(from: createdAtString) {
            createdAt = date
        } else {
            dateFormatter.formatOptions = [.withInternetDateTime]
            createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        }
        
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        if let date = dateFormatter.date(from: updatedAtString) {
            updatedAt = date
        } else {
            dateFormatter.formatOptions = [.withInternetDateTime]
            updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
        }
    }
}

