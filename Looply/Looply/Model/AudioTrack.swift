import Foundation

struct AudioTrack: Codable {
    let name: String
    let artist: Artist
    let album: Album?  // 옵셔널로 변경
    let external_urls: [String: String]
    let duration_ms: Int? // 추가

    struct Artist: Codable {
        let name: String
    }
    
    struct Album: Codable {
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
        case album
        case external_urls
        case duration_ms = "duration_ms" // 추가
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let artists = try container.decode([Artist].self, forKey: .artist)
        artist = artists.first ?? Artist(name: "Unknown")
        album = try container.decodeIfPresent(Album.self, forKey: .album)
        external_urls = try container.decode([String: String].self, forKey: .external_urls)
        duration_ms = try container.decodeIfPresent(Int.self, forKey: .duration_ms) // 추가
    }
}

struct LikedTracksResponse: Codable {
    let items: [LikedTrackItem]
}

struct LikedTrackItem: Codable {
    let track: AudioTrack
}
