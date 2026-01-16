//
//  Group.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-10-17.
//


import Foundation

struct ExpenseGroup: Identifiable, Codable {
    var id: String
    var name: String
    var createdBy: String
    var createdAt: Date
    
    // Members are Firebase userIds
    var members: [String]
    
    // New optional fields for nicer UI
    var description: String?
    var imageUrl: String?
    
    // MARK: - Init from Firebase
    init?(id: String, data: [String: Any], membersDict: [String: Bool]) {
        guard
            let name = data["name"] as? String,
            let createdBy = data["createdBy"] as? String,
            let createdAt = data["createdAt"] as? Int
        else { return nil }
        
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.createdAt = Date(timeIntervalSince1970: TimeInterval(createdAt))
        
        self.members = Array(membersDict.keys)
        self.description = data["description"] as? String
        self.imageUrl = data["imageUrl"] as? String
    }
    
    // MARK: - Init for new group
    init(
        id: String,
        name: String,
        createdBy: String,
        createdAt: Date,
        members: [String],
        description: String? = nil,
        imageUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.members = members
        self.description = description
        self.imageUrl = imageUrl
    }
    
    // MARK: - Firebase dictionaries
    
    var asDict: [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "createdBy": createdBy,
            "createdAt": Int(createdAt.timeIntervalSince1970)
        ]
        
        if let description = description, !description.isEmpty {
            dict["description"] = description
        }
        if let imageUrl = imageUrl, !imageUrl.isEmpty {
            dict["imageUrl"] = imageUrl
        }
        
        return dict
    }
    
    var membersDict: [String: Bool] {
        Dictionary(uniqueKeysWithValues: members.map { ($0, true) })
    }
}
