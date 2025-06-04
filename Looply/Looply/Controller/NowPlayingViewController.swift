import UIKit

class NowPlayingViewController: UIViewController {
    
    // MARK: - IBOutlets (스토리보드)
    @IBOutlet weak var lpRecordImageView: UIImageView!     // LP판
    @IBOutlet weak var albumCoverImageView: UIImageView!   // 앨범 커버 (가운데)
    @IBOutlet weak var toneArmImageView: UIImageView!      // 턴테이블 톤암
    @IBOutlet weak var songTitleLabel: UILabel!            // 노래 제목
    @IBOutlet weak var artistLabel: UILabel!               // 아티스트명
    
    // MARK: - UI Properties (코드로 생성)
    var playPauseButton: UIButton!
    var progressSlider: UISlider!
    var currentTimeLabel: UILabel!
    var totalTimeLabel: UILabel!
    
    // MARK: - New Properties
    var isPlaying: Bool = false
    var updateTimer: Timer?
    var currentTrack: AudioTrack?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupImages()
        setupCodeUI()
        setupConstraints()
        startRealtimeUpdates() // 실시간 업데이트 시작
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRealtimeUpdates() // 화면 벗어날 때 타이머 정지
    }
    
    private func setupImages() {
        // LP판 이미지
        lpRecordImageView.image = UIImage(named: "lp_record")
        lpRecordImageView.contentMode = .scaleAspectFit
        
        // 앨범 커버 (원형으로)
        albumCoverImageView.layer.cornerRadius = albumCoverImageView.frame.width / 2
        albumCoverImageView.clipsToBounds = true
        albumCoverImageView.contentMode = .scaleAspectFill
        
        // 톤암 이미지
        toneArmImageView.image = UIImage(named: "tone_arm")
        toneArmImageView.contentMode = .scaleAspectFit
    }
    
    private func setupCodeUI() {
        // 재생/일시정지 버튼
        playPauseButton = UIButton()
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        playPauseButton.tintColor = .black
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playPauseButton)
        
        // 진행바
        progressSlider = UISlider()
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0.4 // 임시값
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressSlider)
        
        // 현재 시간
        currentTimeLabel = UILabel()
        currentTimeLabel.text = "2:16"
        currentTimeLabel.font = UIFont.systemFont(ofSize: 14)
        currentTimeLabel.textColor = .gray
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentTimeLabel)
        
        // 총 시간
        totalTimeLabel = UILabel()
        totalTimeLabel.text = "3:24"
        totalTimeLabel.font = UIFont.systemFont(ofSize: 14)
        totalTimeLabel.textColor = .gray
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(totalTimeLabel)
        
        playPauseButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)

    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 재생/일시정지 버튼 (노래 제목 옆)
            playPauseButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            playPauseButton.centerYAnchor.constraint(equalTo: songTitleLabel.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 40),
            playPauseButton.heightAnchor.constraint(equalToConstant: 40),
            
            // 진행바 (노래 정보 아래)
            progressSlider.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: 40),
            progressSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 현재 시간 (진행바 아래 왼쪽)
            currentTimeLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 8),
            currentTimeLabel.leadingAnchor.constraint(equalTo: progressSlider.leadingAnchor),
            
            // 총 시간 (진행바 아래 오른쪽)
            totalTimeLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 8),
            totalTimeLabel.trailingAnchor.constraint(equalTo: progressSlider.trailingAnchor)
        ])
    }
    
    // MARK: - Realtime Updates
    private func startRealtimeUpdates() {
        // 3초마다 현재 재생 중인 트랙 확인
        updateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.fetchCurrentlyPlaying()
        }
        
        // 첫 번째 호출
        fetchCurrentlyPlaying()
    }
    
    private func stopRealtimeUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func fetchCurrentlyPlaying() {
        SpotifyAPIManager.shared.getCurrentlyPlayingTrack { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let playingResponse):
                    if let response = playingResponse,
                       let track = response.item {
                        // 현재 재생 중인 트랙 업데이트
                        self?.updateCurrentTrack(track: track, isPlaying: response.is_playing, progressMs: response.progress_ms)
                    } else {
                        // 재생 중인 것이 없음
                        self?.showNoMusicPlaying()
                    }
                case .failure(let error):
                    print("❌ 현재 재생 트랙 가져오기 실패: \(error)")
                    self?.showErrorState()
                }
            }
        }
    }
    
    private func updateCurrentTrack(track: AudioTrack, isPlaying: Bool, progressMs: Int?) {
        currentTrack = track
        
        // UI 업데이트
        songTitleLabel.text = track.name
        artistLabel.text = track.artist.name
        
        // 재생 상태에 따라 LP 회전과 버튼 아이콘
        if isPlaying {
            startLPRotation()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        } else {
            stopLPRotation()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
        
        self.isPlaying = isPlaying
        
        // 진행률 업데이트
        if let progress = progressMs, let duration = track.duration_ms {
            let progressRatio = Float(progress) / Float(duration)
            progressSlider.value = progressRatio
            
            // 시간 표시 업데이트
            currentTimeLabel.text = formatTime(ms: progress)
            totalTimeLabel.text = formatTime(ms: duration)
        }
        
        // 앨범 커버 이미지 로드
        if let imageUrl = track.album?.imageUrl, let url = URL(string: imageUrl) {
            loadAlbumImage(from: url)
        }
    }
    
    private func showNoMusicPlaying() {
        songTitleLabel.text = "재생 중인 음악이 없어요"
        artistLabel.text = "Spotify에서 음악을 재생해보세요"
        stopLPRotation()
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        isPlaying = false
        
        // 기본 LP판 이미지 표시
        albumCoverImageView.image = UIImage(systemName: "music.note")
        progressSlider.value = 0
        currentTimeLabel.text = "0:00"
        totalTimeLabel.text = "0:00"
    }
    
    private func showErrorState() {
        songTitleLabel.text = "연결 오류"
        artistLabel.text = "Spotify 연결을 확인해주세요"
        stopLPRotation()
        isPlaying = false
    }
    
    private func loadAlbumImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                self?.albumCoverImageView.image = UIImage(data: data)
            }
        }.resume()
    }
    
    private func formatTime(ms: Int) -> String {
        let seconds = ms / 1000
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }
    
    // MARK: - Actions
    @objc private func playPauseButtonTapped() {
        // 참고: 실제 Spotify 재생/일시정지 제어는 별도 API 필요
        // 지금은 UI만 토글
        if isPlaying {
            stopLPRotation()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            startLPRotation()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
        isPlaying.toggle()
    }
    
    // MARK: - LP Animation
    private func startLPRotation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 3.0 // 3초에 한 바퀴
        rotation.repeatCount = .infinity
        lpRecordImageView.layer.add(rotation, forKey: "lpRotation")
    }

    private func stopLPRotation() {
        lpRecordImageView.layer.removeAnimation(forKey: "lpRotation")
    }
}
