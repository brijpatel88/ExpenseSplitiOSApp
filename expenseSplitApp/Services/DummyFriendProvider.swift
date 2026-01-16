//
//  DummyFriendProvider.swift
//  expenseSplitApp
//
//  Created by Brijesh Patel on 2025-11-28.
//


import Foundation

struct DummyFriendProvider {

    static func loadDummyFriends(count: Int) -> [FriendModel] {
        let names = [
            "Ava Sharma", "Liam Patel", "Sophia Singh",
            "Ethan Wong", "Mia Chen", "Noah Kumar",
            "Isabella Brown", "Lucas Garcia", "Amelia Wilson"
        ]

        let emails = [
            "ava@example.com", "liam@example.com", "sophia@example.com",
            "ethan@example.com", "mia@example.com", "noah@example.com",
            "isabella@example.com", "lucas@example.com", "amelia@example.com"
        ]

        var friends: [FriendModel] = []

        for i in 0..<min(count, names.count) {
            friends.append(
                FriendModel(
                    id: "dummy_\(i+1)",
                    name: names[i],
                    email: emails[i]
                )
            )
        }
        return friends
    }

    static func loadDummyRequests() -> [FriendRequestModel] {
        [
            FriendRequestModel(
                id: "dummy_req_1",
                fromUserId: "dummy_req_1",
                name: "Rahul Sharma",
                email: "rahul@example.com"
            ),
            FriendRequestModel(
                id: "dummy_req_2",
                fromUserId: "dummy_req_2",
                name: "Emily Zhang",
                email: "emily@example.com"
            )
        ]
    }
}
