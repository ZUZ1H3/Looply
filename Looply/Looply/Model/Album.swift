//
//  Album.swift
//  Looply
//
//  Created by 주지혜 on 6/4/25.
//

import Foundation

struct Album: Codable {
    let id: String
    let name: String
    let artists: [Artist]
    let images: [AlbumImage]
    let external_urls: [String: String]
    let release_date: String?
    
    struct Artist: Codable {
        let name: String
    }
    
    struct AlbumImage: Codable {
        let url: String
        let height: Int?
        let width: Int?
    }
    
    // 첫 번째 아티스트 이름
    var artistName: String {
        return artists.first?.name ?? "Unknown"
    }
    
    // 가장 적당한 크기의 이미지
    var imageUrl: String? {
        return images.first?.url
    }
}

struct LikedAlbumsResponse: Codable {
    let items: [LikedAlbumItem]
}

struct LikedAlbumItem: Codable {
    let album: Album
}
