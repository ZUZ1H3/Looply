//
//  AudioTrack.swift
//  Looply
//
//  Created by 주지혜 on 6/4/25.
//

import Foundation

struct AudioTrack: Codable {
    let name: String
    let artist: Artist
    let album: Album  // 🎵 앨범 정보 추가!
    let external_urls: [String: String]

    struct Artist: Codable {
        let name: String
    }
    
    struct Album: Codable {  // 🎵 앨범 구조 추가!
        let id: String
        let name: String
        let images: [AlbumImage]
        let external_urls: [String: String]
        
        struct AlbumImage: Codable {
            let url: String
            let height: Int?
            let width: Int?
        }
        
        var imageUrl: String? {
            return images.first?.url
        }
    }

    enum CodingKeys: String, CodingKey {
        case name
        case artist = "artists"
        case album  // 🎵 앨범 키 추가!
        case external_urls
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)

        let artists = try container.decode([Artist].self, forKey: .artist)
        artist = artists.first ?? Artist(name: "Unknown")
        
        album = try container.decode(Album.self, forKey: .album)  // 🎵 앨범 디코딩!

        external_urls = try container.decode([String: String].self, forKey: .external_urls)
    }
}

struct LikedTracksResponse: Codable {
    let items: [LikedTrackItem]
}

struct LikedTrackItem: Codable {
    let track: AudioTrack
}
