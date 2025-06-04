//
//  CurrentlyPlayingResponse.swift
//  Looply
//
//  Created by 주지혜 on 6/5/25.
//

import Foundation

struct CurrentlyPlayingResponse: Codable {
    let is_playing: Bool
    let progress_ms: Int?
    let item: AudioTrack?
    
    enum CodingKeys: String, CodingKey {
        case is_playing
        case progress_ms
        case item
    }
}
