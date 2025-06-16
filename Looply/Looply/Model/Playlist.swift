//
//  Playlist.swift
//  Looply
//
//  Created by 주지혜 on 6/5/25.
//

import Foundation
// MARK: - Playlist Models
struct Playlist: Codable {
    let id: String
    let name: String
    let description: String?
    let images: [PlaylistImage]?
    let tracks: TracksInfo
    let owner: PlaylistOwner
    let external_urls: [String: String]
    
    struct PlaylistImage: Codable {
        let url: String
        let height: Int?
        let width: Int?
    }
    
    struct TracksInfo: Codable {
        let total: Int
    }
    
    struct PlaylistOwner: Codable {
        let id: String
        let display_name: String?
    }
    
    // 가장 적당한 크기의 이미지
    var imageUrl: String? {
        return images?.first?.url
    }
    
    // 트랙 개수
    var trackCount: Int {
        return tracks.total
    }
    
    // 소유자 이름
    var ownerName: String {
        return owner.display_name ?? "Unknown"
    }
}

struct PlaylistsResponse: Codable {
    let items: [Playlist]
    let total: Int
    let limit: Int
    let offset: Int
}
