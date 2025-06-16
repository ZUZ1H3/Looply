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
    
    // 중간 시간 보간용 추가 properties
    var lastUpdateTime: Date?
    var lastProgressMs: Int?
    var progressTimer: Timer?
    
    // 파장 효과용 추가
    var waveBackgroundView: UIView!
    var waveLayer1: CAShapeLayer!
    var waveLayer2: CAShapeLayer!
    var waveLayer3: CAShapeLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupImages()
        setupCodeUI()
        setupConstraints()
        startRealtimeUpdates() // 실시간 업데이트 시작
        setupWaveBackground() // 파장 배경 추가
        setupNavigationBar()
        setupStoryboardUIStyles()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRealtimeUpdates()
        stopProgressTimer() // 🆕 추가
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
        
        // 진행바 스타일 변경
        progressSlider = UISlider()
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0.4
        
        // 진행바 색상을 검정색으로 변경
        progressSlider.minimumTrackTintColor = .black        // 진행된 부분 (파란색 → 검정색)
        progressSlider.maximumTrackTintColor = .white    // 남은 부분 (회색 유지)
        progressSlider.thumbTintColor = .black               // 동그란 제어 부분 (검정색)
                
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressSlider)
        
        // 현재 시간
        currentTimeLabel = UILabel()
        currentTimeLabel.text = "2:16"
        currentTimeLabel.font = UIFont.systemFont(ofSize: 14)
        currentTimeLabel.textColor = .black
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
    
    // MARK: - Realtime Updates (10초 간격)
    private func startRealtimeUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.fetchCurrentlyPlaying()
        }
    
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
            startProgressTimer() // 🆕 진행률 타이머 시작
        } else {
            stopLPRotation()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            stopProgressTimer() // 🆕 진행률 타이머 정지
        }
        
        self.isPlaying = isPlaying
        
        // 🆕 마지막 업데이트 시간과 진행률 저장
        if let progress = progressMs {
            lastUpdateTime = Date()
            lastProgressMs = progress
        }
        
        // 🆕 진행률 즉시 업데이트
        updateProgressDisplay()
        
        // 앨범 커버 이미지 로드
        if let imageUrl = track.album?.imageUrl, let url = URL(string: imageUrl) {
            loadAlbumImage(from: url)
        }
    }
    
    // MARK: - 🆕 중간 시간 보간 기능
    private func startProgressTimer() {
        stopProgressTimer()
        // 1초마다 진행률 업데이트 (부드러운 시간 흐름)
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateProgressDisplay()
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
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
    private func updateProgressDisplay() {
        guard let lastUpdate = lastUpdateTime,
              let lastProgress = lastProgressMs,
              let duration = currentTrack?.duration_ms,
              isPlaying else { return }
        
        // 마지막 업데이트 이후 경과 시간 계산
        let elapsedSeconds = Date().timeIntervalSince(lastUpdate)
        let currentProgress = lastProgress + Int(elapsedSeconds * 1000) // ms로 변환
        
        // 총 시간을 넘지 않도록 제한
        let clampedProgress = min(currentProgress, duration)
        
        let progressRatio = Float(clampedProgress) / Float(duration)
        progressSlider.value = progressRatio
        
        // 시간 표시 업데이트 (1초마다 부드럽게 변함)
        currentTimeLabel.text = formatTime(ms: clampedProgress)
        totalTimeLabel.text = formatTime(ms: duration)
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
                if let image = UIImage(data: data) {
                    self?.albumCoverImageView.image = image
                    self?.updateWaveColors(from: image) // 🆕 파장 색상 업데이트
                }
            }
        }.resume()
    }
    
    private func formatTime(ms: Int) -> String {
        let seconds = ms / 1000
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }
    
    // MARK: - 🆕 스토리보드 UI 스타일링
    private func setupStoryboardUIStyles() {
        // 1. 노래 제목 라벨 스타일 (크고 두껍게)
        songTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        songTitleLabel.textColor = .black
        
        // 2. 아티스트 라벨 스타일 (작고 얇게)
        artistLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        artistLabel.textColor = .darkGray
    }
    
    // MARK: - 🆕 네비게이션 바 타이틀 스타일링
    private func setupNavigationBar() {
        // 뒤로가기 버튼 색상
        navigationController?.navigationBar.tintColor = .black
        
        // 네비게이션 바 투명하게
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        
        // 타이틀 스타일 (두껍게)
        title = "Looply 🎵"
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 20, weight: .bold) // 두껍게 변경
        ]
    }
    
    // MARK: - 🆕 실제 재생 제어 버튼
    @objc private func playPauseButtonTapped() {
        if isPlaying {
            // 실제 Spotify 일시정지
            SpotifyAPIManager.shared.pausePlayback { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.stopLPRotation()
                        self?.stopProgressTimer()
                        self?.playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                        self?.isPlaying = false
                        print("✅ 재생 일시정지 성공")
                    case .failure(let error):
                        print("❌ 일시정지 실패: \(error)")
                        self?.showPlaybackErrorAlert(isPlaying: true, error: error)
                    }
                }
            }
        } else {
            // 실제 Spotify 재생
            SpotifyAPIManager.shared.resumePlayback { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.startLPRotation()
                        self?.startProgressTimer()
                        self?.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                        self?.isPlaying = true
                        print("✅ 재생 재개 성공")
                    case .failure(let error):
                        print("❌ 재생 실패: \(error)")
                        self?.showPlaybackErrorAlert(isPlaying: false, error: error)
                    }
                }
            }
        }
    }

    // MARK: - Error Alert
    private func showPlaybackErrorAlert(isPlaying: Bool, error: SpotifyAPIManager.APIError) {
        let action = isPlaying ? "일시정지" : "재생"
        var title = "\(action) 제어 실패"
        var message = ""
        
        switch error {
        case .apiError(403, _):
            title = "Premium 계정이 필요해요"
            message = "무료 계정에서는 Spotify 앱에서 직접 재생을 제어해주세요. 🎵\n\nLooply는 자동으로 변화를 감지할 거예요!"
        case .apiError(404, _):
            title = "재생 중인 기기가 없어요"
            message = "Spotify 앱을 먼저 실행하고 음악을 재생해주세요. 📱"
        case .noToken, .tokenExpired:
            title = "로그인이 필요해요"
            message = "Spotify 계정에 다시 로그인해주세요. 🔐"
        default:
            title = "\(action) 실패"
            message = "잠시 후 다시 시도해주세요. 또는 Spotify 앱에서 직접 제어해주세요. 🎶"
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Spotify 앱 열기 버튼 (Premium 계정 문제일 때)
        if case .apiError(403, _) = error {
            alert.addAction(UIAlertAction(title: "Spotify 열기", style: .default) { _ in
                if let url = URL(string: "spotify://") {
                    UIApplication.shared.open(url)
                }
            })
        }
        
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - LP Animation
    private func startLPRotation() {
        // 더 부드러운 회전 (타이밍 함수 추가)
        let lpRotation = CABasicAnimation(keyPath: "transform.rotation")
        lpRotation.fromValue = 0
        lpRotation.toValue = Double.pi * 2
        lpRotation.duration = 10.0 // 더 천천히 (10초)
        lpRotation.repeatCount = .infinity
        lpRotation.timingFunction = CAMediaTimingFunction(name: .linear) // 일정한 속도
        lpRecordImageView.layer.add(lpRotation, forKey: "lpRotation")
        
        let albumRotation = CABasicAnimation(keyPath: "transform.rotation")
        albumRotation.fromValue = 0
        albumRotation.toValue = Double.pi * 2
        albumRotation.duration = 10.0
        albumRotation.repeatCount = .infinity
        albumRotation.timingFunction = CAMediaTimingFunction(name: .linear)
        albumCoverImageView.layer.add(albumRotation, forKey: "albumRotation")
        startWaveAnimation()
    }

    private func stopLPRotation() {
        // LP판 회전 정지
        lpRecordImageView.layer.removeAnimation(forKey: "lpRotation")
        
        // 앨범 커버 회전 정지
        albumCoverImageView.layer.removeAnimation(forKey: "albumRotation")
        stopWaveAnimation()
    }
    
    // MARK: - 🆕 파장 배경 설정
    private func setupWaveBackground() {
        // 파장 배경 컨테이너
        waveBackgroundView = UIView()
        waveBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(waveBackgroundView, at: 0) // 맨 뒤에 배치
        
        NSLayoutConstraint.activate([
            waveBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            waveBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            waveBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            waveBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 다층 파장 생성
        createWaveLayers()
    }
    
    private func createWaveLayers() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // 파장 1 (가장 뒤, 큰 파장)
        waveLayer1 = CAShapeLayer()
        waveLayer1.fillColor = UIColor.systemBlue.withAlphaComponent(0.1).cgColor
        waveLayer1.path = createWavePath(amplitude: 40, frequency: 2, phase: 0, width: screenWidth, height: screenHeight).cgPath
        waveBackgroundView.layer.addSublayer(waveLayer1)
        
        // 파장 2 (중간, 중간 파장)
        waveLayer2 = CAShapeLayer()
        waveLayer2.fillColor = UIColor.systemPurple.withAlphaComponent(0.08).cgColor
        waveLayer2.path = createWavePath(amplitude: 25, frequency: 3, phase: .pi/2, width: screenWidth, height: screenHeight).cgPath
        waveBackgroundView.layer.addSublayer(waveLayer2)
        
        // 파장 3 (앞, 작은 파장)
        waveLayer3 = CAShapeLayer()
        waveLayer3.fillColor = UIColor.systemPink.withAlphaComponent(0.06).cgColor
        waveLayer3.path = createWavePath(amplitude: 15, frequency: 4, phase: .pi, width: screenWidth, height: screenHeight).cgPath
        waveBackgroundView.layer.addSublayer(waveLayer3)
    }
    
    private func createWavePath(amplitude: CGFloat, frequency: CGFloat, phase: CGFloat, width: CGFloat, height: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let centerY = height / 2
        
        // 시작점
        path.move(to: CGPoint(x: 0, y: centerY))
        
        // 파장 그리기
        for x in stride(from: 0, through: width, by: 2) {
            let angle = (x / width) * frequency * 2 * .pi + phase
            let y = centerY + amplitude * sin(angle)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // 화면 아래쪽까지 채우기
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.close()
        
        return path
    }
    
    // MARK: - 🆕 재생 상태에 따른 파장 애니메이션
    private func startWaveAnimation() {
        // 강한 파장 (재생 중)
        animateWave(layer: waveLayer1, duration: 3.0, amplitude: 50)
        animateWave(layer: waveLayer2, duration: 2.5, amplitude: 35)
        animateWave(layer: waveLayer3, duration: 2.0, amplitude: 20)
    }
    
    private func stopWaveAnimation() {
        // 잔잔한 파장 (일시정지)
        animateWave(layer: waveLayer1, duration: 6.0, amplitude: 15)
        animateWave(layer: waveLayer2, duration: 5.0, amplitude: 10)
        animateWave(layer: waveLayer3, duration: 4.0, amplitude: 5)
    }
    
    // 🌊 훨씬 더 역동적인 파장 애니메이션
    private func animateWave(layer: CAShapeLayer, duration: TimeInterval, amplitude: CGFloat) {
        let animation = CAKeyframeAnimation(keyPath: "path")
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        var paths: [CGPath] = []
        
        // 더 극적인 파장 변화
        for i in 0...15 { // 10 → 15개로 증가 (더 부드러운 변화)
            let progress = CGFloat(i) / 15.0
            let phase = progress * .pi * 4 // 더 많은 주기
            
            // 진폭이 더 극적으로 변화
            let amplitudeMultiplier = 0.3 + 1.4 * abs(sin(phase * 2)) // 0.3~1.7 범위
            let currentAmplitude = amplitude * amplitudeMultiplier
            
            // 주파수도 동적으로 변화
            let dynamicFrequency = 1.5 + 1.0 * sin(phase)
            
            let path = createWavePath(
                amplitude: currentAmplitude,
                frequency: dynamicFrequency,
                phase: phase,
                width: screenWidth,
                height: screenHeight
            )
            paths.append(path.cgPath)
        }
        
        animation.values = paths
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        layer.add(animation, forKey: "waveAnimation")
    }
    
    // MARK: - 🆕 앨범 색상에 맞춰 파장 색상 변경
    private func updateWaveColors(from image: UIImage) {
        guard let dominantColor = image.averageColor else {
            // 기본값도 더 강렬하게
            setVibrantDefaultWaves()
            return
        }
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        dominantColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // 🔥 훨씬 더 강렬한 색상
        let waveColor1 = UIColor(hue: hue, saturation: min(saturation * 2.5, 1.0), brightness: min(brightness + 0.3, 1.0), alpha: 0.4) // 채도 2.5배, 투명도 40%
        let waveColor2 = UIColor(hue: fmod(hue + 0.2, 1.0), saturation: min(saturation * 2.0, 1.0), brightness: min(brightness + 0.2, 1.0), alpha: 0.35)
        let waveColor3 = UIColor(hue: fmod(hue - 0.2, 1.0), saturation: min(saturation * 1.8, 1.0), brightness: min(brightness + 0.25, 1.0), alpha: 0.3)
        
        waveLayer1.fillColor = waveColor1.cgColor
        waveLayer2.fillColor = waveColor2.cgColor
        waveLayer3.fillColor = waveColor3.cgColor
    }
    private func setVibrantDefaultWaves() {
        // 기본값도 강렬하게
        waveLayer1.fillColor = UIColor(red: 1.0, green: 0.3, blue: 0.6, alpha: 0.4).cgColor  // 비브런트 핑크
        waveLayer2.fillColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.35).cgColor // 비브런트 블루
        waveLayer3.fillColor = UIColor(red: 0.6, green: 0.3, blue: 1.0, alpha: 0.3).cgColor  // 비브런트 퍼플
    }
}
