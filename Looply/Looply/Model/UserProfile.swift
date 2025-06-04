//
//  UserProfile.swift
//  Looply
//
//  Created by 주지혜 on 6/4/25.
//

import Foundation

struct UserProfile: Codable {
    let display_name: String
    let followers: Followers
    let external_urls: [String: String]
    let id: String
    
    struct Followers: Codable {
        let total: Int
    }
}
