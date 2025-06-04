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
    let images: [ProfileImage]? // 이 부분 추가
    let id: String
    
    struct Followers: Codable {
        let total: Int
    }
    
    struct ProfileImage: Codable {
            let url: String
            let height: Int?
            let width: Int?
        }
}
