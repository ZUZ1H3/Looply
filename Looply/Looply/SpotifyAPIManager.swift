import Foundation

// MARK: - API Manager

class SpotifyAPIManager {
    static let shared = SpotifyAPIManager()

    private init() {}
    
    // MARK: - Constants
    struct Constants {
        static let baseAPIURL = "https://api.spotify.com/v1"
    }

    // MARK: - Custom Error Types
    enum APIError: Error {
        case noToken
        case invalidURL
        case noData
        case tokenExpired
        case apiError(Int, String)
        
        var localizedDescription: String {
            switch self {
            case .noToken:
                return "로그인 토큰이 없습니다"
            case .invalidURL:
                return "잘못된 URL입니다"
            case .noData:
                return "데이터를 받을 수 없습니다"
            case .tokenExpired:
                return "토큰이 만료되었습니다"
            case .apiError(let status, let message):
                return "API 에러 (\(status)): \(message)"
            }
        }
    }
    
    // MARK: - User Profile API
    func getUserProfile(completion: @escaping (Result<UserProfile, APIError>) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "spotifyAccessToken") else {
            completion(.failure(.noToken))
            return
        }
        
        guard let url = URL(string: Constants.baseAPIURL + "/me") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("🛎 HTTP 상태 코드: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 401 {
                    // 토큰 만료
                    UserDefaults.standard.removeObject(forKey: "spotifyAccessToken")
                    completion(.failure(.tokenExpired))
                    return
                }
            }
            
            if let error = error {
                completion(.failure(.apiError(0, error.localizedDescription)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let profile = try JSONDecoder().decode(UserProfile.self, from: data)
                completion(.success(profile))
            } catch {
                completion(.failure(.apiError(-1, error.localizedDescription)))
            }
        }.resume()
    }
    
    // MARK: - Liked Tracks API
    func getLikedTracks(completion: @escaping (Result<[AudioTrack], APIError>) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "spotifyAccessToken") else {
            completion(.failure(.noToken))
            return
        }
        
        guard let url = URL(string: Constants.baseAPIURL + "/me/tracks?limit=20") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("🛎 HTTP 상태 코드: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 401 {
                    UserDefaults.standard.removeObject(forKey: "spotifyAccessToken")
                    completion(.failure(.tokenExpired))
                    return
                }
            }
            
            if let error = error {
                completion(.failure(.apiError(0, error.localizedDescription)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(LikedTracksResponse.self, from: data)
                let tracks = result.items.map { $0.track }
                completion(.success(tracks))
            } catch {
                completion(.failure(.apiError(-1, error.localizedDescription)))
            }
        }.resume()
    }
}
