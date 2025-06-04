import Foundation

struct AudioTrack: Codable {
    let name: String
    let artist: Artist
    let album: Album?  // 옵셔널로 변경
    let external_urls: [String: String]
    
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
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let artists = try container.decode([Artist].self, forKey: .artist)
        artist = artists.first ?? Artist(name: "Unknown")
        
        // album을 옵셔널로 디코딩
        album = try container.decodeIfPresent(Album.self, forKey: .album)
        external_urls = try container.decode([String: String].self, forKey: .external_urls)
    }
}

struct LikedTracksResponse: Codable {
    let items: [LikedTrackItem]
}

struct LikedTrackItem: Codable {
    let track: AudioTrack
}
