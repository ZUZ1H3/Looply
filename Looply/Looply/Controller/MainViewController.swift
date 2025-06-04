import UIKit

class MainViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // 화면의 제목 텍스트
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var albumsCollectionView: UICollectionView!

    var likedTracks: [AudioTrack] = []
    var likedAlbums: [Album] = []

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
        
        fetchUserProfile()
        fetchLikedTracksAndExtractAlbums()
    }
    
    // 사용자 정보 가져오기
    private func fetchUserProfile() {
        SpotifyAPIManager.shared.getUserProfile { [weak self] result in
            switch result {
            case .success(let profile):
                DispatchQueue.main.async {
                    self?.titleLabel.text = "안녕하세요, \(profile.display_name)님!"
                }
            case .failure(let error):
                print("❌ 프로필 가져오기 실패: \(error)")
                DispatchQueue.main.async {
                    self?.titleLabel.text = "🎵 나만의 음악"
                }
            }
        }
    }
    
    /// 좋아요한 곡에서 앨범들 추출
    private func fetchLikedTracksAndExtractAlbums() {
        SpotifyAPIManager.shared.getLikedTracks { [weak self] result in
            switch result {
            case .success(let tracks):
                // 🎵 곡들에서 앨범 정보 추출
                var albumsDict: [String: Album] = [:]
                
                for track in tracks {
                    let albumId = track.album.id
                    if albumsDict[albumId] == nil {
                        let album = Album(
                            id: track.album.id,
                            name: track.album.name,
                            artists: [Album.Artist(name: track.artist.name)],
                            images: track.album.images.map { albumImage in
                                Album.AlbumImage(url: albumImage.url, height: albumImage.height, width: albumImage.width)
                            },
                            external_urls: track.album.external_urls,
                            release_date: nil
                        )
                        albumsDict[albumId] = album
                    }
                }
                
                let uniqueAlbums = Array(albumsDict.values)
                self?.likedAlbums = Array(uniqueAlbums.prefix(10))
                
                DispatchQueue.main.async {
                    self?.titleLabel.text = "지혜님이 좋아하는 앨범들 📀"
                    self?.albumsCollectionView.reloadData()  // ✅ CollectionView로 변경
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
