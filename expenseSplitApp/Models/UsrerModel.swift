//
//  UsrerModel.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-06.
//

import Foundation

struct UserModel: Identifiable, Codable {
    // Firebase Auth UID
    var id: String
    
    var fullName: String
    var email: String
    var phone: String
    var location: String
    var bio: String
    
    // New fields
    var profileImageUrl: String?
    var joinedAt: Date
    var lastUpdated: Date?
    
    // MARK: - Init from Firebase dictionary
    init?(id: String, data: [String: Any]) {
        guard
            let fullName = data["fullName"] as? String,
            let email = data["email"] as? String
        else {
            return nil
        }
        
        self.id = id
        self.fullName = fullName
        self.email = email
        self.phone = data["phone"] as? String ?? ""
        self.location = data["location"] as? String ?? ""
        self.bio = data["bio"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String
        
        // joinedAt (required-ish, but we default if missing)
        if let joinedAtTimestamp = data["joinedAt"] as? Int {
            self.joinedAt = Date(timeIntervalSince1970: TimeInterval(joinedAtTimestamp))
        } else {
            // fallback if older user without this field
            self.joinedAt = Date()
        }
        
        // lastUpdated (optional)
        if let lastUpdatedTimestamp = data["lastUpdated"] as? Int {
            self.lastUpdated = Date(timeIntervalSince1970: TimeInterval(lastUpdatedTimestamp))
        } else {
            self.lastUpdated = nil
        }
    }
    
    // MARK: - Init for creating a new profile
    init(
        id: String,
        fullName: String,
        email: String,
        phone: String = "",
        location: String = "",
        bio: String = "",
        profileImageUrl: String? = nil,
        joinedAt: Date = Date(),
        lastUpdated: Date? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.location = location
        self.bio = bio
        self.profileImageUrl = profileImageUrl
        self.joinedAt = joinedAt
        self.lastUpdated = lastUpdated
    }
    
    // MARK: - Convert to dictionary for Firebase
    var asDict: [String: Any] {
        var dict: [String: Any] = [
            "fullName": fullName,
            "email": email,
            "phone": phone,
            "location": location,
            "bio": bio,
            "joinedAt": Int(joinedAt.timeIntervalSince1970)
        ]
        
        if let url = profileImageUrl {
            dict["profileImageUrl"] = url
        }
        
        if let lastUpdated = lastUpdated {
            dict["lastUpdated"] = Int(lastUpdated.timeIntervalSince1970)
        }
        
        return dict
    }
}
