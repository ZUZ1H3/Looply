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
    let external_urls: [String: String]

    struct Artist: Codable {
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case name
        case artist = "artists"
        case external_urls
    }

    // Spotify는 artists가 배열이므로 첫 번째 아티스트만 사용
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)

        let artists = try container.decode([Artist].self, forKey: .artist)
        artist = artists.first ?? Artist(name: "Unknown")

        external_urls = try container.decode([String: String].self, forKey: .external_urls)
    }
}

struct LikedTracksResponse: Codable {
    let items: [LikedTrackItem]
}

struct LikedTrackItem: Codable {
    let track: AudioTrack
}
