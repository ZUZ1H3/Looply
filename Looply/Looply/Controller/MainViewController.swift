import UIKit

class MainViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // 화면의 제목 텍스트
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var albumsCollectionView: UICollectionView!

    // 새로 추가할 UI 요소들
       var headerView: UIView!
       var greetingLabel: UILabel!
       var profileImageView: UIImageView!
       
       var likedTracks: [AudioTrack] = []
       var likedAlbums: [Album] = []
       var userProfile: UserProfile? // 사용자 프로필 저장


    // 화면이 처음 나타날 때 실행
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = "🎵 로딩 중..."
        albumsCollectionView.delegate = self
        albumsCollectionView.dataSource = self
        
        // 🎨 기본 셀 등록
        albumsCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "AlbumCell")
        
        // 🎨 카드 레이아웃 설정
        if let layout = albumsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 16
            layout.minimumInteritemSpacing = 16
            layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        }
        setupHeaderUI() // 헤더 UI 설정

        fetchUserProfile()
        fetchLikedTracksAndExtractAlbums()
    }
    
    // 사용자 정보 가져오기
    // 사용자 정보 가져오기 (수정됨)
    private func fetchUserProfile() {
        SpotifyAPIManager.shared.getUserProfile { [weak self] result in
            switch result {
            case .success(let profile):
                self?.userProfile = profile
                DispatchQueue.main.async {
                    // 인사말 업데이트
                    self?.greetingLabel.text = "안녕하세요, \(profile.display_name)님!"
                    
                    // 프로필 이미지 로드 (있다면)
                    if let imageUrl = profile.images?.first?.url,
                       let url = URL(string: imageUrl) {
                        self?.loadProfileImage(from: url)
                    }
                }
            case .failure(let error):
                print("❌ 프로필 가져오기 실패: \(error)")
                DispatchQueue.main.async {
                    self?.greetingLabel.text = "🎵 나만의 음악"
                }
            }
        }
    }
    // 프로필 이미지 로드 함수
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("❌ 프로필 이미지 로드 실패: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self?.profileImageView.image = UIImage(data: data)
            }
        }.resume()
    }
    
    // 새로운 헤더 UI 설정 함수
    private func setupHeaderUI() {
        // 헤더 컨테이너 뷰 생성
        headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        // 인사말 라벨 생성
        greetingLabel = UILabel()
        greetingLabel.text = "🎵 로딩 중..."
        greetingLabel.font = UIFont.boldSystemFont(ofSize: 24)
        greetingLabel.textColor = .black
        greetingLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(greetingLabel)
        
        // 프로필 이미지 뷰 생성
        profileImageView = UIImageView()
        profileImageView.backgroundColor = .lightGray
        profileImageView.layer.cornerRadius = 25 // 원형으로 만들기
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(profileImageView)
        
        // Auto Layout 설정
        NSLayoutConstraint.activate([
            // 헤더 뷰 제약조건
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            // 인사말 라벨 제약조건
            greetingLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            greetingLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            greetingLabel.trailingAnchor.constraint(lessThanOrEqualTo: profileImageView.leadingAnchor, constant: -10),
            
            // 프로필 이미지 제약조건
            profileImageView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            profileImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // 기존 titleLabel 숨기기 (새로운 greetingLabel로 대체)
        titleLabel.isHidden = true
    }
    /// 좋아요한 곡에서 앨범들 추출
    private func fetchLikedTracksAndExtractAlbums() {
        SpotifyAPIManager.shared.getLikedTracks { [weak self] result in
            switch result {
            case .success(let tracks):
                // 🎵 곡들에서 앨범 정보 추출
                var albumsDict: [String: Album] = [:]
                
                for track in tracks {
                    // album이 옵셔널이므로 안전하게 접근
                    guard let trackAlbum = track.album else { continue }
                    
                    let albumId = trackAlbum.id
                    if albumsDict[albumId] == nil {
                        let album = Album(
                            id: trackAlbum.id,
                            name: trackAlbum.name,
                            artists: [Album.Artist(name: track.artist.name)],
                            images: trackAlbum.images.map { albumImage in
                                Album.AlbumImage(url: albumImage.url, height: albumImage.height, width: albumImage.width)
                            },
                            external_urls: trackAlbum.external_urls,
                            release_date: nil
                        )
                        albumsDict[albumId] = album
                    }
                }
                
                let uniqueAlbums = Array(albumsDict.values)
                self?.likedAlbums = Array(uniqueAlbums.prefix(10))
                
                DispatchQueue.main.async {
                    self?.titleLabel.text = "지혜님이 좋아하는 앨범들 📀"
                    self?.albumsCollectionView.reloadData()
                }
                
                print("✅ 앨범 \(uniqueAlbums.count)개 추출 완료!")
                
            case .failure(let error):
                print("❌ 트랙 가져오기 실패: \(error)")
            }
        }
    }
    // MARK: - CollectionView DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return likedAlbums.count
    }
    
    // MARK: - CollectionView Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("🎵 앨범 클릭됨: \(indexPath.item)")
        
        let selectedAlbum = likedAlbums[indexPath.item]
        print("📀 선택된 앨범: \(selectedAlbum.name)")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "AlbumDetailViewController") as? AlbumDetailViewController {
            print("✅ AlbumDetailViewController 생성 성공")
            detailVC.album = selectedAlbum
            
            if let navController = navigationController {
                print("✅ NavigationController 존재함")
                navController.pushViewController(detailVC, animated: true)
                print("✅ pushViewController 호출됨")
            } else {
                print("❌ NavigationController가 nil임!")
                // 대안: present로 화면 전환
                detailVC.modalPresentationStyle = .fullScreen
                present(detailVC, animated: true)
            }
        } else {
            print("❌ AlbumDetailViewController를 찾을 수 없어요!")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let album = likedAlbums[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumCell", for: indexPath)
        
        // 🎨 셀 기본 스타일
        cell.backgroundColor = .white
        cell.layer.cornerRadius = 12
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.layer.shadowOpacity = 0.1
        cell.layer.shadowRadius = 4
        
        // 기존 뷰들 제거
        cell.subviews.forEach { $0.removeFromSuperview() }
        
        // 📀 앨범 이미지 뷰 생성
        let imageView = UIImageView(frame: CGRect(x: 8, y: 8, width: 134, height: 134))
        imageView.backgroundColor = .systemGray5 // 로딩 중 배경
        imageView.layer.cornerRadius = 8
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        // 🌐 실제 앨범 커버 이미지 로드
        if let imageUrl = album.imageUrl, let url = URL(string: imageUrl) {
            loadImage(from: url, into: imageView)
        }
        
        // 📝 앨범명 라벨
        let titleLabel = UILabel(frame: CGRect(x: 8, y: 150, width: 134, height: 30))
        titleLabel.text = album.name
        titleLabel.font = UIFont.boldSystemFont(ofSize: 12)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        
        // 👤 아티스트명 라벨
        let artistLabel = UILabel(frame: CGRect(x: 8, y: 175, width: 134, height: 20))
        artistLabel.text = album.artistName
        artistLabel.font = UIFont.systemFont(ofSize: 10)
        artistLabel.textColor = .gray
        artistLabel.textAlignment = .center
        
        cell.addSubview(imageView)
        cell.addSubview(titleLabel)
        cell.addSubview(artistLabel)
        
        return cell
    }

    // 🌐 이미지 로드 함수 추가
    private func loadImage(from url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ 이미지 로드 실패: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
            }
        }.resume()
    }
    
    // MARK: - CollectionView Layout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 200)
    }
}
