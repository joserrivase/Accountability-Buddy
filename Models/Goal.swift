//
//  Goal.swift
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

import Foundation

enum TrackingMethod: String, Codable, CaseIterable {
    case inputNumbers = "input_numbers"
    case trackDaysCompleted = "track_days_completed"
    case inputList = "input_list"
    
    var displayName: String {
        switch self {
        case .inputNumbers:
            return "Input Numbers"
        case .trackDaysCompleted:
            return "Track Days Completed"
        case .inputList:
            return "Input List"
        }
    }
    
    var description: String {
        switch self {
        case .inputNumbers:
            return "Track the amount of something you have done"
        case .trackDaysCompleted:
            return "Track every day you do something"
        case .inputList:
            return "Track specific things you have done"
        }
    }
}

struct Goal: Identifiable, Codable {
    let id: UUID
    let name: String
    let trackingMethod: TrackingMethod
    let creatorId: UUID
    let buddyId: UUID?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case trackingMethod = "tracking_method"
        case creatorId = "creator_id"
        case buddyId = "buddy_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID, name: String, trackingMethod: TrackingMethod, creatorId: UUID, buddyId: UUID? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.trackingMethod = trackingMethod
        self.creatorId = creatorId
        self.buddyId = buddyId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        trackingMethod = try container.decode(TrackingMethod.self, forKey: .trackingMethod)
        creatorId = try container.decode(UUID.self, forKey: .creatorId)
        buddyId = try container.decodeIfPresent(UUID.self, forKey: .buddyId)
        
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
        try container.encode(name, forKey: .name)
        try container.encode(trackingMethod, forKey: .trackingMethod)
        try container.encode(creatorId, forKey: .creatorId)
        try container.encodeIfPresent(buddyId, forKey: .buddyId)
        
        // Encode dates as ISO8601 strings
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
    }
}

struct GoalProgress: Identifiable, Codable {
    let id: UUID
    let goalId: UUID
    let userId: UUID
    var numericValue: Double?
    var completedDays: [String]? // Array of date strings (YYYY-MM-DD)
    var listItems: [GoalListItem]? // Array of completed items with timestamps
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case userId = "user_id"
        case numericValue = "numeric_value"
        case completedDays = "completed_days"
        case listItems = "list_items"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID, goalId: UUID, userId: UUID, numericValue: Double? = nil, completedDays: [String]? = nil, listItems: [GoalListItem]? = nil, updatedAt: Date = Date()) {
        self.id = id
        self.goalId = goalId
        self.userId = userId
        self.numericValue = numericValue
        self.completedDays = completedDays
        self.listItems = listItems
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        goalId = try container.decode(UUID.self, forKey: .goalId)
        userId = try container.decode(UUID.self, forKey: .userId)
        numericValue = try container.decodeIfPresent(Double.self, forKey: .numericValue)
        completedDays = try container.decodeIfPresent([String].self, forKey: .completedDays)
        listItems = try container.decodeIfPresent([GoalListItem].self, forKey: .listItems)
        
        // Decode date from ISO8601 string
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
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
        try container.encode(goalId, forKey: .goalId)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(numericValue, forKey: .numericValue)
        try container.encodeIfPresent(completedDays, forKey: .completedDays)
        try container.encodeIfPresent(listItems, forKey: .listItems)
        
        // Encode date as ISO8601 string
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
    }
}

// Combined model for displaying goal with progress
struct GoalWithProgress: Identifiable, Equatable {
    let goal: Goal
    var creatorProgress: GoalProgress?
    var buddyProgress: GoalProgress?
    
    var id: UUID { goal.id }
    
    static func == (lhs: GoalWithProgress, rhs: GoalWithProgress) -> Bool {
        return lhs.goal.id == rhs.goal.id &&
               lhs.creatorProgress?.id == rhs.creatorProgress?.id &&
               lhs.buddyProgress?.id == rhs.buddyProgress?.id
    }
}

struct GoalListItem: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let date: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case date
    }
    
    init(id: UUID = UUID(), title: String, date: Date = Date()) {
        self.id = id
        self.title = title
        self.date = date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        let dateString = try container.decode(String.self, forKey: .date)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let decodedDate = formatter.date(from: dateString) {
            date = decodedDate
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: dateString) ?? Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: date), forKey: .date)
    }
}

