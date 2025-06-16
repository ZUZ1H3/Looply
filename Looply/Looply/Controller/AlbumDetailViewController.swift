import UIKit

class AlbumDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var albumTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var tracksTableView: UITableView!
    
    var album: Album!
    var albumTracks: [AudioTrack] = []
    
    // LP판 배경 이미지뷰 추가
    var lpBackgroundView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLPBackground()
        setupAlbumInfo()
        setupAlbumTouchGesture()
        fetchAlbumTracks()
        setupBackButton()
    }
    
    private func setupAlbumTouchGesture() {
        // 앨범 이미지에 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(albumImageTapped))
        albumImageView.isUserInteractionEnabled = true
        albumImageView.addGestureRecognizer(tapGesture)
    }
    @objc private func albumImageTapped() {
        // 햅틱 피드백 (더 부드럽게)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // 더 스무스하고 천천히
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            // LP판을 더 아래로 이동
            self.lpBackgroundView.transform = CGAffineTransform(translationX: 0, y: 18)
            // 앨범 커버를 살짝 스케일 다운
            self.albumImageView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            // 원상태로 돌아가는 애니메이션 (더 부드럽게)
            UIView.animate(withDuration: 0.4, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: .curveEaseInOut, animations: {
                // 원래 위치로 복귀
                self.lpBackgroundView.transform = .identity
                self.albumImageView.transform = .identity
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 레이아웃이 완료된 후 마스크 적용
        setupAlbumImageMask()
    }
    
    private func setupUI() {
        // LP 스타일 디자인
        albumImageView.contentMode = .scaleAspectFill
        albumImageView.clipsToBounds = true
        
        // 제목과 아티스트 스타일링 (Looply 감성)
        albumTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        albumTitleLabel.textColor = .black
        albumTitleLabel.textAlignment = .center
        
        artistNameLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        artistNameLabel.textColor = .gray
        artistNameLabel.textAlignment = .center
        
        tracksTableView.delegate = self
        tracksTableView.dataSource = self
        tracksTableView.register(UITableViewCell.self, forCellReuseIdentifier: "TrackCell")
        tracksTableView.separatorStyle = .singleLine
        tracksTableView.backgroundColor = .clear // 완전 투명
        tracksTableView.separatorColor = UIColor.black.withAlphaComponent(0.1) // 연한 구분선
    }

    private func setupLPBackground() {
        // LP판 배경 뷰 생성
        lpBackgroundView = UIImageView()
        lpBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        // 실제 LP 이미지 사용
        lpBackgroundView.image = UIImage(named: "lp_record") // 이미지 이름으로 변경
        lpBackgroundView.alpha = 1.0
        lpBackgroundView.contentMode = .scaleAspectFit
        
        // 앨범 이미지뷰 뒤에 배치
        view.insertSubview(lpBackgroundView, belowSubview: albumImageView)
        
        NSLayoutConstraint.activate([
            lpBackgroundView.centerXAnchor.constraint(equalTo: albumImageView.centerXAnchor),
            lpBackgroundView.centerYAnchor.constraint(equalTo: albumImageView.centerYAnchor, constant: 45),
            lpBackgroundView.widthAnchor.constraint(equalTo: albumImageView.widthAnchor, multiplier: 0.95), // 1.2 → 0.8로 줄이기
            lpBackgroundView.heightAnchor.constraint(equalTo: albumImageView.heightAnchor, multiplier: 0.95) // 1.2 → 0.8로 줄이기
        ])
    }
    
    private func setupAlbumImageMask() {
        guard albumImageView.bounds != .zero else { return }
        
        let maskLayer = CAShapeLayer()
        
        // 이미지뷰 크기
        let imageSize = albumImageView.bounds
        
        // 라운드 사각형 패스 생성 (라운드 약하게)
        let roundedRectPath = UIBezierPath(roundedRect: imageSize, cornerRadius: 8) // 20 → 12로 줄임
        
        // 아래쪽 가운데 원형 홀 패스 생성 (홀 더 작게)
        let holeRadius: CGFloat = 25 // 35 → 25로 줄임
        let holeCenter = CGPoint(x: imageSize.width / 2, y: imageSize.height - 1) // 살짝 위로 올림
        let holePath = UIBezierPath(arcCenter: holeCenter, radius: holeRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        
        // 라운드 사각형에서 원형 홀 빼기
        roundedRectPath.append(holePath)
        maskLayer.path = roundedRectPath.cgPath
        maskLayer.fillRule = .evenOdd // 홀 뚫기
        
        // 마스크 적용
        albumImageView.layer.mask = maskLayer
        
        // 앨범 이미지만 살짝 투명하게 (LP판이 비치도록)
        albumImageView.alpha = 0.9
    }
    
    private func setupAlbumInfo() {
        albumTitleLabel.text = album.name
        artistNameLabel.text = album.artistName
        
        // 앨범 커버 이미지 로드
        if let imageUrl = album.imageUrl, let url = URL(string: imageUrl) {
            loadImage(from: url, into: albumImageView)
        }
    }
    
    // MARK: - 뒤로가기 버튼 설정
    private func setupBackButton() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .black
        backButton.backgroundColor = .clear // 배경 없애기
        
        // 버튼 크기 설정
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        
        // 제약조건 설정 (왼쪽 상단)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 30),
            backButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // 버튼 액션 연결
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // 다른 UI 요소들보다 앞에 배치
        view.bringSubviewToFront(backButton)
    }

    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func fetchAlbumTracks() {
        print("🔍 앨범 ID로 트랙 검색 시작: \(album.id)")
        
        SpotifyAPIManager.shared.getAlbumTracks(albumId: album.id) { [weak self] result in
            switch result {
            case .success(let tracks):
                print("✅ 트랙 \(tracks.count)개 가져오기 성공")
                self?.albumTracks = tracks
                DispatchQueue.main.async {
                    self?.tracksTableView.reloadData()
                }
            case .failure(let error):
                print("❌ 앨범 트랙 가져오기 실패: \(error)")
                print("🔍 실패한 앨범 ID: \(self?.album.id ?? "unknown")")
                
                // 에러 처리 - 사용자에게 알림
                DispatchQueue.main.async {
                    self?.showErrorAlert()
                }
            }
        }
    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(title: "트랙을 불러올 수 없어요", message: "잠시 후 다시 시도해주세요", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
                self?.setupAlbumImageMask()
                self?.setupDynamicGradientBackground() // 여기서 호출!
            }
        }.resume()
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumTracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = albumTracks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath)
        
        // 트랙 번호와 이름
        cell.textLabel?.text = "\(indexPath.row + 1)  \(track.name)"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cell.textLabel?.textColor = .black
        
        // 아티스트명
        cell.detailTextLabel?.text = track.artist.name
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        cell.detailTextLabel?.textColor = .gray
        
        // 실제 재생시간 표시
        let timeLabel = UILabel()
        if let duration = track.duration_ms {
            let minutes = duration / 60000
            let seconds = (duration % 60000) / 1000
            timeLabel.text = "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            timeLabel.text = "3:13"
        }
        timeLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        timeLabel.textColor = .gray
        timeLabel.sizeToFit()
        cell.accessoryView = timeLabel
        
        // 반투명 배경 적용
        cell.backgroundColor = UIColor.white.withAlphaComponent(0.2) // 반투명 흰색
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let track = albumTracks[indexPath.row]
        if let url = URL(string: track.external_urls["spotify"] ?? "") {
            UIApplication.shared.open(url)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60 // 조금 더 높게 설정
    }
    private func setupDynamicGradientBackground() {
        guard let albumImage = albumImageView.image else { return }
        let dominantColors = extractDominantColors(from: albumImage)
        
        // 그라데이션 레이어 생성
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        
        // 더 다양하고 선명한 색상으로 그라데이션 생성
        let enhancedColors = createEnhancedGradient(from: dominantColors)
        gradientLayer.colors = enhancedColors.map { $0.cgColor }
        
        // 대각선 그라데이션으로 변경
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        // 여러 위치에 색상 배치 (더 드라마틱하게)
        gradientLayer.locations = [0.0, 0.4, 0.7, 1.0]
        
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // 더 역동적인 애니메이션 추가
        addDynamicWaveAnimation(to: gradientLayer)
    }

    private func createEnhancedGradient(from baseColors: [UIColor]) -> [UIColor] {
        guard let mainColor = baseColors.first else {
            // 기본 색상도 더 선명하게
            return [
                UIColor(red: 0.9, green: 0.7, blue: 1.0, alpha: 1.0),    // 연보라
                UIColor(red: 1.0, green: 0.8, blue: 0.9, alpha: 1.0),    // 연핑크
                UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0),    // 연하늘
                UIColor(red: 0.9, green: 1.0, blue: 0.8, alpha: 1.0)     // 연초록
            ]
        }
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        mainColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // 훨씬 더 선명하고 채도 높은 색상들
        let color1 = UIColor(hue: hue, saturation: min(saturation * 2.0, 1.0), brightness: min(brightness + 0.2, 1.0), alpha: 0.6) // 채도 2배
        let color2 = UIColor(hue: fmod(hue + 0.15, 1.0), saturation: min(saturation * 1.8, 1.0), brightness: min(brightness + 0.15, 1.0), alpha: 0.5)
        let color3 = UIColor(hue: fmod(hue - 0.15, 1.0), saturation: min(saturation * 1.6, 1.0), brightness: min(brightness + 0.25, 1.0), alpha: 0.7)
        let color4 = UIColor(hue: fmod(hue + 0.3, 1.0), saturation: min(saturation * 1.4, 1.0), brightness: min(brightness + 0.1, 1.0), alpha: 0.4)
        
        return [color1, color2, color3, color4]
    }

    private func addDynamicWaveAnimation(to gradientLayer: CAGradientLayer) {
        // 물감 흘러내리는 느낌의 애니메이션
        let colorAnimation = CAKeyframeAnimation(keyPath: "colors")
        guard let originalColors = gradientLayer.colors else { return }
        
        // 더 드라마틱한 색상 변화 (물감이 섞이는 느낌)
        let intenseColors = originalColors.map { color in
            let cgColor = color as! CGColor
            return UIColor(cgColor: cgColor).withAlphaComponent(1.0).cgColor // 완전 불투명
        }
        
        let fadeColors = originalColors.map { color in
            let cgColor = color as! CGColor
            return UIColor(cgColor: cgColor).withAlphaComponent(0.2).cgColor // 거의 투명
        }
        
        let midColors = originalColors.map { color in
            let cgColor = color as! CGColor
            return UIColor(cgColor: cgColor).withAlphaComponent(0.7).cgColor
        }
        
        // 물감이 퍼지듯 천천히 변화
        colorAnimation.values = [originalColors, intenseColors, midColors, fadeColors, midColors, originalColors]
        colorAnimation.duration = 12.0 // 더 천천히
        colorAnimation.repeatCount = .infinity
        colorAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // 물감 흘러내리는 효과 (위치 변화)
        let locationAnimation = CAKeyframeAnimation(keyPath: "locations")
        locationAnimation.values = [
            [0.0, 0.3, 0.6, 1.0],
            [0.2, 0.5, 0.8, 1.2],     // 아래로 흘러내림
            [0.1, 0.4, 0.7, 1.1],
            [-0.1, 0.2, 0.5, 0.9],    // 위로 올라감
            [0.0, 0.3, 0.6, 1.0]
        ]
        locationAnimation.duration = 15.0
        locationAnimation.repeatCount = .infinity
        locationAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // 물감 번짐 효과 (그라데이션 방향 변화)
        let startPointAnimation = CAKeyframeAnimation(keyPath: "startPoint")
        startPointAnimation.values = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 0.2, y: 0.3),   // 물감이 번지는 느낌
            CGPoint(x: 0.1, y: 0.1),
            CGPoint(x: 0.3, y: 0.2),
            CGPoint(x: 0, y: 0)
        ]
        startPointAnimation.duration = 20.0
        startPointAnimation.repeatCount = .infinity
        
        gradientLayer.add(colorAnimation, forKey: "colorFlow")
        gradientLayer.add(locationAnimation, forKey: "paintDrip")
        gradientLayer.add(startPointAnimation, forKey: "paintSpread")
    }

    private func extractDominantColors(from image: UIImage) -> [UIColor] {
        // 이미지에서 주요 색상 3개 추출
        guard let cgImage = image.cgImage else { return [UIColor.white, UIColor.gray] }
        
        // 간단한 색상 추출 (실제로는 더 정교한 알고리즘 사용 가능)
        var colors: [UIColor] = []
        
        // 이미지 크기 줄여서 샘플링
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIAreaAverage")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
        
        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            // 평균 색상을 기반으로 그라데이션 색상 생성
            colors = generateGradientColors(from: uiImage.averageColor ?? UIColor.gray)
        }
        
        return colors.isEmpty ? [UIColor.white, UIColor.gray] : colors
    }

    private func generateGradientColors(from baseColor: UIColor) -> [UIColor] {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        baseColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // 기본 색상에서 변형된 색상들 생성
        let color1 = UIColor(hue: hue, saturation: saturation * 0.3, brightness: min(brightness + 0.2, 1.0), alpha: 1.0)
        let color2 = UIColor(hue: hue, saturation: saturation * 0.2, brightness: min(brightness + 0.1, 1.0), alpha: 1.0)
        let color3 = UIColor(hue: hue, saturation: saturation * 0.1, brightness: min(brightness + 0.15, 1.0), alpha: 1.0)
        
        return [color1, color2, color3]
    }

    private func addWaveAnimation(to gradientLayer: CAGradientLayer) {
        let animation = CAKeyframeAnimation(keyPath: "colors")
        
        guard let originalColors = gradientLayer.colors else { return }
        
        let wavyColors1 = originalColors.map { color in
            let cgColor = color as! CGColor // force cast (색상 배열이라는 걸 알고 있으니까)
            return UIColor(cgColor: cgColor).withAlphaComponent(0.2).cgColor
        }
        
        let wavyColors2 = originalColors.map { color in
            let cgColor = color as! CGColor
            return UIColor(cgColor: cgColor).withAlphaComponent(0.4).cgColor
        }
        
        animation.values = [originalColors, wavyColors1, wavyColors2, originalColors]
        animation.duration = 4.0
        animation.repeatCount = .infinity
        animation.autoreverses = true
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        gradientLayer.add(animation, forKey: "waveAnimation")
    }
}
// UIImage 확장 (평균 색상 구하기)
extension UIImage {
    var averageColor: UIColor? {
        guard let cgImage = cgImage else { return nil }
        
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIAreaAverage")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        let bitmap = cgImage.dataProvider?.data
        let data = CFDataGetBytePtr(bitmap)
        
        let r = CGFloat(data?[0] ?? 0) / 255.0
        let g = CGFloat(data?[1] ?? 0) / 255.0
        let b = CGFloat(data?[2] ?? 0) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
