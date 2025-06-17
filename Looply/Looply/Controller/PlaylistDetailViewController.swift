import UIKit

class PlaylistDetailViewController: UIViewController {
    
    @IBOutlet weak var playlistImageView: UIImageView!
    @IBOutlet weak var playlistTitleLabel: UILabel!
    @IBOutlet weak var playlistInfoLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tracksTableView: UITableView!
    
    // MARK: - LP 스타일 추가 (코드로 생성)
    private var lpBackgroundView: UIImageView!
    
    // MARK: - Properties
    var playlist: Playlist!
    var tracks: [AudioTrack] = []
    var filteredTracks: [AudioTrack] = []
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🚀 PlaylistDetailViewController viewDidLoad 시작!!!")
        print("🎵 전달받은 playlist: \(playlist?.name ?? "nil")")
        
        // IBOutlet 연결 상태 확인
        print("🔗 playlistImageView: \(playlistImageView != nil ? "연결됨" : "nil")")
        print("🔗 playlistTitleLabel: \(playlistTitleLabel != nil ? "연결됨" : "nil")")
        print("🔗 playlistInfoLabel: \(playlistInfoLabel != nil ? "연결됨" : "nil")")
        print("🔗 searchBar: \(searchBar != nil ? "연결됨" : "nil")")
        print("🔗 tracksTableView: \(tracksTableView != nil ? "연결됨" : "nil")")
        // 안전장치 추가
        guard playlist != nil else {
            print("❌ playlist가 nil입니다!")
            showErrorState(message: "플레이리스트 정보를 찾을 수 없습니다.")
            return
        }
        
        print("✅ playlist 존재: \(playlist.name)")
        setupInitialState()
        
        print("✅ PlaylistDetailViewController viewDidLoad 끝!!!")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupPlaylistImageMask()
    }
    
    // MARK: - Setup Methods
    private func setupInitialState() {
        setupUI()
        setupLPBackground()
        setupPlaylistInfo()
        setupPlaylistTouchGesture()
        setupBackButton()
        setupSearchBar()
        fetchPlaylistTracks()
    }
    
    private func setupUI() {
        // 네비게이션 바
        title = "플레이리스트"
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 18, weight: .medium)
        ]
        
        // 플레이리스트 이미지 스타일링
        playlistImageView?.contentMode = .scaleAspectFill
        playlistImageView?.clipsToBounds = true
        playlistImageView?.backgroundColor = .systemGray5
        
        // 플레이리스트 제목 스타일링
        playlistTitleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        playlistTitleLabel?.textColor = .black
        playlistTitleLabel?.textAlignment = .center
        playlistTitleLabel?.numberOfLines = 2
        
        // 플레이리스트 정보 스타일링
        playlistInfoLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        playlistInfoLabel?.textColor = .gray
        playlistInfoLabel?.textAlignment = .center
        
        // 검색 바 스타일링
        searchBar?.searchBarStyle = .minimal
        searchBar?.backgroundColor = .systemGray6
        searchBar?.layer.cornerRadius = 12
        searchBar?.clipsToBounds = true
        searchBar?.placeholder = "곡 검색..."
        
        // 테이블뷰 설정
        tracksTableView?.delegate = self
        tracksTableView?.dataSource = self
        tracksTableView?.backgroundColor = .clear
        tracksTableView?.separatorStyle = .none
        tracksTableView?.showsVerticalScrollIndicator = false
        tracksTableView?.keyboardDismissMode = .onDrag
    }
    
    private func setupSearchBar() {
        searchBar?.delegate = self
    }
    
    private func setupLPBackground() {
        guard playlistImageView != nil else { return }
        
        lpBackgroundView = UIImageView()
        lpBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        lpBackgroundView.image = UIImage(named: "lp_record")
        lpBackgroundView.alpha = 1.0
        lpBackgroundView.contentMode = .scaleAspectFit
        
        // 플레이리스트 이미지뷰 뒤에 배치
        view.insertSubview(lpBackgroundView, belowSubview: playlistImageView)
        
        NSLayoutConstraint.activate([
            lpBackgroundView.centerXAnchor.constraint(equalTo: playlistImageView.centerXAnchor),
            lpBackgroundView.centerYAnchor.constraint(equalTo: playlistImageView.centerYAnchor, constant: 45),
            lpBackgroundView.widthAnchor.constraint(equalTo: playlistImageView.widthAnchor, multiplier: 0.95),
            lpBackgroundView.heightAnchor.constraint(equalTo: playlistImageView.heightAnchor, multiplier: 0.95)
        ])
    }
    
    private func setupPlaylistTouchGesture() {
        guard playlistImageView != nil else { return }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playlistImageTapped))
        playlistImageView.isUserInteractionEnabled = true
        playlistImageView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func playlistImageTapped() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            self.lpBackgroundView?.transform = CGAffineTransform(translationX: 0, y: 18)
            self.playlistImageView?.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.4, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: .curveEaseInOut, animations: {
                self.lpBackgroundView?.transform = .identity
                self.playlistImageView?.transform = .identity
            })
        }
    }
    
    private func setupPlaylistImageMask() {
        guard let playlistImageView = playlistImageView, playlistImageView.bounds != .zero else { return }
        
        let maskLayer = CAShapeLayer()
        let imageSize = playlistImageView.bounds
        
        // 라운드 사각형 패스 생성
        let roundedRectPath = UIBezierPath(roundedRect: imageSize, cornerRadius: 8)
        
        // 아래쪽 가운데 원형 홀 패스 생성
        let holeRadius: CGFloat = 25
        let holeCenter = CGPoint(x: imageSize.width / 2, y: imageSize.height - 1)
        let holePath = UIBezierPath(arcCenter: holeCenter, radius: holeRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        
        // 라운드 사각형에서 원형 홀 빼기
        roundedRectPath.append(holePath)
        maskLayer.path = roundedRectPath.cgPath
        maskLayer.fillRule = .evenOdd
        
        // 마스크 적용
        playlistImageView.layer.mask = maskLayer
        playlistImageView.alpha = 0.9
    }
    
    private func setupPlaylistInfo() {
        playlistTitleLabel?.text = playlist.name
        playlistInfoLabel?.text = "\(playlist.trackCount)곡"
        
        // 플레이리스트 이미지 설정
        if let imageUrl = playlist.imageUrl, let url = URL(string: imageUrl) {
            loadImage(from: url, into: playlistImageView)
        } else {
            setupDefaultPlaylistImage()
        }
    }
    
    private func setupDefaultPlaylistImage() {
        guard let playlistImageView = playlistImageView else { return }
        
        if playlist.id == "liked_songs" {
            // 좋아요한 곡 모음용 특별 이미지
            playlistImageView.backgroundColor = .systemPink.withAlphaComponent(0.2)
            
            let heartImageView = UIImageView()
            heartImageView.image = UIImage(systemName: "heart.fill")
            heartImageView.tintColor = .systemPink
            heartImageView.contentMode = .scaleAspectFit
            heartImageView.translatesAutoresizingMaskIntoConstraints = false
            playlistImageView.addSubview(heartImageView)
            
            NSLayoutConstraint.activate([
                heartImageView.centerXAnchor.constraint(equalTo: playlistImageView.centerXAnchor),
                heartImageView.centerYAnchor.constraint(equalTo: playlistImageView.centerYAnchor),
                heartImageView.widthAnchor.constraint(equalToConstant: 80),
                heartImageView.heightAnchor.constraint(equalToConstant: 80)
            ])
        } else {
            playlistImageView.backgroundColor = .systemGray5
            
            let musicImageView = UIImageView()
            musicImageView.image = UIImage(systemName: "music.note.list")
            musicImageView.tintColor = .systemGray3
            musicImageView.contentMode = .scaleAspectFit
            musicImageView.translatesAutoresizingMaskIntoConstraints = false
            playlistImageView.addSubview(musicImageView)
            
            NSLayoutConstraint.activate([
                musicImageView.centerXAnchor.constraint(equalTo: playlistImageView.centerXAnchor),
                musicImageView.centerYAnchor.constraint(equalTo: playlistImageView.centerYAnchor),
                musicImageView.widthAnchor.constraint(equalToConstant: 80),
                musicImageView.heightAnchor.constraint(equalToConstant: 80)
            ])
        }
    }
    
    private func setupBackButton() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .black
        backButton.backgroundColor = .clear
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 30),
            backButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.bringSubviewToFront(backButton)
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Fetch Playlist Tracks
    private func fetchPlaylistTracks() {
        isLoading = true
        showLoadingState()
        
        if playlist.id == "liked_songs" {
            fetchLikedTracks()
        } else {
            fetchSpotifyPlaylistTracks()
        }
    }
    
    private func fetchLikedTracks() {
        SpotifyAPIManager.shared.getLikedTracks { [weak self] result in
            DispatchQueue.main.async {
                self?.handleTracksResult(result)
            }
        }
    }
    
    private func fetchSpotifyPlaylistTracks() {
        SpotifyAPIManager.shared.getPlaylistTracks(playlistId: playlist.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleTracksResult(result)
            }
        }
    }
    
    private func handleTracksResult(_ result: Result<[AudioTrack], SpotifyAPIManager.APIError>) {
        isLoading = false
        
        switch result {
        case .success(let tracks):
            self.tracks = tracks
            self.filteredTracks = tracks
            showTracks()
        case .failure(let error):
            print("❌ 곡 가져오기 실패: \(error)")
            showErrorState(message: "플레이리스트를 불러올 수 없습니다.")
        }
    }
    
    private func showLoadingState() {
        // 로딩 상태 표시 (필요시 구현)
    }
    
    private func showTracks() {
        tracksTableView?.reloadData()
        updateTrackCount()
    }
    
    private func updateTrackCount() {
        let count = filteredTracks.count
        playlistInfoLabel?.text = "\(count)곡"
        
        // 검색 상태에 따른 표시
        if !filteredTracks.isEmpty && filteredTracks.count != tracks.count {
            playlistInfoLabel?.text = "\(count)곡 (전체 \(tracks.count)곡)"
        }
    }
    
    private func showErrorState(message: String) {
        let alert = UIAlertController(title: "로딩 실패", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Search Methods
    private func filterTracks(with searchText: String) {
        if searchText.isEmpty {
            filteredTracks = tracks
        } else {
            filteredTracks = tracks.filter { track in
                track.name.localizedCaseInsensitiveContains(searchText) ||
                track.artist.name.localizedCaseInsensitiveContains(searchText) ||
                (track.album?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        tracksTableView?.reloadData()
        updateTrackCount()
    }
    
    // MARK: - Image Loading
    private func loadImage(from url: URL, into imageView: UIImageView?) {
        guard let imageView = imageView else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
                self?.setupPlaylistImageMask()
                self?.setupDynamicGradientBackground()
            }
        }.resume()
    }
    
    // MARK: - Dynamic Background
    private func setupDynamicGradientBackground() {
        guard let playlistImage = playlistImageView?.image else { return }
        let dominantColors = extractDominantColors(from: playlistImage)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        
        let enhancedColors = createEnhancedGradient(from: dominantColors)
        gradientLayer.colors = enhancedColors.map { $0.cgColor }
        
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.locations = [0.0, 0.4, 0.7, 1.0]
        
        view.layer.insertSublayer(gradientLayer, at: 0)
        addDynamicWaveAnimation(to: gradientLayer)
    }
    
    private func extractDominantColors(from image: UIImage) -> [UIColor] {
        return [image.averageColor ?? UIColor.gray]
    }
    
    private func createEnhancedGradient(from baseColors: [UIColor]) -> [UIColor] {
        guard let mainColor = baseColors.first else {
            return [
                UIColor(red: 0.9, green: 0.7, blue: 1.0, alpha: 1.0),
                UIColor(red: 1.0, green: 0.8, blue: 0.9, alpha: 1.0),
                UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0),
                UIColor(red: 0.9, green: 1.0, blue: 0.8, alpha: 1.0)
            ]
        }
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        mainColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        let color1 = UIColor(hue: hue, saturation: min(saturation * 2.0, 1.0), brightness: min(brightness + 0.2, 1.0), alpha: 0.6)
        let color2 = UIColor(hue: fmod(hue + 0.15, 1.0), saturation: min(saturation * 1.8, 1.0), brightness: min(brightness + 0.15, 1.0), alpha: 0.5)
        let color3 = UIColor(hue: fmod(hue - 0.15, 1.0), saturation: min(saturation * 1.6, 1.0), brightness: min(brightness + 0.25, 1.0), alpha: 0.7)
        let color4 = UIColor(hue: fmod(hue + 0.3, 1.0), saturation: min(saturation * 1.4, 1.0), brightness: min(brightness + 0.1, 1.0), alpha: 0.4)
        
        return [color1, color2, color3, color4]
    }
    
    private func addDynamicWaveAnimation(to gradientLayer: CAGradientLayer) {
        let colorAnimation = CAKeyframeAnimation(keyPath: "colors")
        guard let originalColors = gradientLayer.colors else { return }
        
        let intenseColors = originalColors.map { color in
            let cgColor = color as! CGColor
            return UIColor(cgColor: cgColor).withAlphaComponent(1.0).cgColor
        }
        
        let fadeColors = originalColors.map { color in
            let cgColor = color as! CGColor
            return UIColor(cgColor: cgColor).withAlphaComponent(0.2).cgColor
        }
        
        let midColors = originalColors.map { color in
            let cgColor = color as! CGColor
            return UIColor(cgColor: cgColor).withAlphaComponent(0.7).cgColor
        }
        
        colorAnimation.values = [originalColors, intenseColors, midColors, fadeColors, midColors, originalColors]
        colorAnimation.duration = 12.0
        colorAnimation.repeatCount = .infinity
        colorAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        gradientLayer.add(colorAnimation, forKey: "colorFlow")
    }
    
    // MARK: - Helper Methods
    private func formatDuration(ms: Int) -> String {
        let seconds = ms / 1000
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }
}

// MARK: - UISearchBarDelegate
extension PlaylistDetailViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterTracks(with: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        filterTracks(with: "")
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension PlaylistDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let track = filteredTracks[indexPath.row]
        
        // 셀 스타일링
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        // 컨테이너 뷰
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowOpacity = 0.08
        containerView.layer.shadowRadius = 2
        containerView.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(containerView)
        
        // 트랙 번호
        let trackNumberLabel = UILabel()
        trackNumberLabel.text = "\(indexPath.row + 1)"
        trackNumberLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        trackNumberLabel.textColor = .systemGray
        trackNumberLabel.textAlignment = .center
        trackNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(trackNumberLabel)
        
        // 앨범 이미지
        let albumImageView = UIImageView()
        albumImageView.backgroundColor = .systemGray5
        albumImageView.layer.cornerRadius = 6
        albumImageView.contentMode = .scaleAspectFill
        albumImageView.clipsToBounds = true
        albumImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(albumImageView)
        
        // 곡 정보 스택뷰
        let infoStackView = UIStackView()
        infoStackView.axis = .vertical
        infoStackView.spacing = 2
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(infoStackView)
        
        // 곡 제목
        let titleLabel = UILabel()
        titleLabel.text = track.name
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 1
        infoStackView.addArrangedSubview(titleLabel)
        
        // 아티스트명
        let artistLabel = UILabel()
        artistLabel.text = track.artist.name
        artistLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        artistLabel.textColor = .systemGray
        infoStackView.addArrangedSubview(artistLabel)
        
        // 재생 시간
        let durationLabel = UILabel()
        durationLabel.text = formatDuration(ms: track.duration_ms ?? 0)
        durationLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        durationLabel.textColor = .systemGray2
        durationLabel.textAlignment = .right
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(durationLabel)
        
        // 제약 조건
        NSLayoutConstraint.activate([
            // 컨테이너
            containerView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),
            containerView.heightAnchor.constraint(equalToConstant: 70),
            
            // 트랙 번호
            trackNumberLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            trackNumberLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            trackNumberLabel.widthAnchor.constraint(equalToConstant: 30),
            
            // 앨범 이미지
            albumImageView.leadingAnchor.constraint(equalTo: trackNumberLabel.trailingAnchor, constant: 12),
            albumImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            albumImageView.widthAnchor.constraint(equalToConstant: 50),
            albumImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // 곡 정보
            infoStackView.leadingAnchor.constraint(equalTo: albumImageView.trailingAnchor, constant: 12),
            infoStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            infoStackView.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -12),
            
            // 재생 시간
            durationLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            durationLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        // 앨범 이미지 로드
        if let imageUrl = track.album?.imageUrl, let url = URL(string: imageUrl) {
            loadImage(from: url, into: albumImageView)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTrack = filteredTracks[indexPath.row]
        
        // 선택 효과
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.1, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    cell.transform = CGAffineTransform.identity
                }
            }
        }
        
        print("🎵 선택된 곡: \(selectedTrack.name) - \(selectedTrack.artist.name)")
    }
}
