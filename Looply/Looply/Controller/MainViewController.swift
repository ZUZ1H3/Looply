import UIKit

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // 화면의 제목 텍스트
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tracksTableView: UITableView!

    var likedTracks: [AudioTrack] = []

    // 화면이 처음 나타날 때 실행
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 처음에는 로딩 메시지 표시
        titleLabel.text = "🎵 로딩 중..."
        // TableView 설정 추가
        tracksTableView.delegate = self
        tracksTableView.dataSource = self
        tracksTableView.register(UITableViewCell.self, forCellReuseIdentifier: "TrackCell")
        
        // 사용자 이름 가져와서 인사말 만들기
        fetchUserProfile()
        fetchLikedTracks() // 이 줄 추가!

    }
    
    // 사용자 정보 가져오기
    private func fetchUserProfile() {
        SpotifyAPIManager.shared.getUserProfile { [weak self] result in
            switch result {
            case .success(let profile):
                // 성공하면 인사말 표시
                DispatchQueue.main.async {
                    self?.titleLabel.text = "안녕하세요, \(profile.display_name)님!"
                }
            case .failure(let error):
                // 실패하면 기본 메시지 표시
                print("❌ 프로필 가져오기 실패: \(error)")
                DispatchQueue.main.async {
                    self?.titleLabel.text = "🎵 나만의 음악"
                }
            }
        }
    }
    
    /// 좋아요한 트랙 가져오기
    private func fetchLikedTracks() {
        SpotifyAPIManager.shared.getLikedTracks { [weak self] result in
            switch result {
            case .success(let tracks):
                self?.likedTracks = Array(tracks.prefix(10))
                DispatchQueue.main.async {
                    self?.titleLabel.text = "내가 좋아요한 음악 ❤️"
                    self?.tracksTableView.reloadData() // 주석 해제!
                }
                print("✅ 좋아요 트랙 \(tracks.count)개 로드 완료")
            case .failure(let error):
                print("❌ 좋아요 트랙 가져오기 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - TableView DataSource
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return likedTracks.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let track = likedTracks[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath)
            cell.textLabel?.text = "\(track.name) - \(track.artist.name)"
            return cell
        }
        
        // MARK: - TableView Delegate
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            
            let track = likedTracks[indexPath.row]
            if let url = URL(string: track.external_urls["spotify"] ?? "") {
                UIApplication.shared.open(url)
            }
        }
}
