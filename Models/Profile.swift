//
//  Profile.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import Foundation

struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var username: String?
    var name: String? // Kept for backward compatibility
    var firstName: String?
    var lastName: String?
    var profileImageUrl: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case name
        case firstName = "first_name"
        case lastName = "last_name"
        case profileImageUrl = "profile_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID, userId: UUID, username: String? = nil, name: String? = nil, firstName: String? = nil, lastName: String? = nil, profileImageUrl: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.username = username
        self.name = name
        self.firstName = firstName
        self.lastName = lastName
        self.profileImageUrl = profileImageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        
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
        try container.encodeIfPresent(username, forKey: .username)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        
        // Encode dates as ISO8601 strings
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
    }
}

// Struct for updating profile - only includes updatable fields
struct ProfileUpdate: Codable {
    var username: String?
    var name: String? // Kept for backward compatibility
    var firstName: String?
    var lastName: String?
    var profileImageUrl: String?
    var updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case username
        case name
        case firstName = "first_name"
        case lastName = "last_name"
        case profileImageUrl = "profile_image_url"
        case updatedAt = "updated_at"
    }
    
    init(username: String? = nil, name: String? = nil, firstName: String? = nil, lastName: String? = nil, profileImageUrl: String? = nil) {
        self.username = username
        self.name = name
        self.firstName = firstName
        self.lastName = lastName
        self.profileImageUrl = profileImageUrl
        
        // Set updated_at to current timestamp in ISO8601 format
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.updatedAt = dateFormatter.string(from: Date())
    }
    
    // Custom encode to only include non-nil values
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Only encode fields that are not nil
        if let username = username {
            try container.encode(username, forKey: .username)
        }
        if let name = name {
            try container.encode(name, forKey: .name)
        }
        if let firstName = firstName {
            try container.encode(firstName, forKey: .firstName)
        }
        if let lastName = lastName {
            try container.encode(lastName, forKey: .lastName)
        }
        if let profileImageUrl = profileImageUrl {
            try container.encode(profileImageUrl, forKey: .profileImageUrl)
        }
        
        // Always encode updated_at
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// Extension to get display name (prefers firstName + lastName, falls back to name)
extension Profile {
    var displayName: String {
        if let firstName = firstName, let lastName = lastName, !firstName.isEmpty {
            if !lastName.isEmpty {
                return "\(firstName) \(lastName)"
            } else {
                return firstName
            }
        } else if let firstName = firstName, !firstName.isEmpty {
            return firstName
        } else if let name = name, !name.isEmpty {
            return name
        } else if let username = username, !username.isEmpty {
            return username
        } else {
            return "User"
        }
    }
    
    // Equatable conformance
    static func == (lhs: Profile, rhs: Profile) -> Bool {
        return lhs.id == rhs.id &&
               lhs.userId == rhs.userId &&
               lhs.username == rhs.username &&
               lhs.name == rhs.name &&
               lhs.firstName == rhs.firstName &&
               lhs.lastName == rhs.lastName &&
               lhs.profileImageUrl == rhs.profileImageUrl &&
               lhs.createdAt == rhs.createdAt &&
               lhs.updatedAt == rhs.updatedAt
    }
}

