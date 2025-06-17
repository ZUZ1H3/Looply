import UIKit

class SearchViewController: UIViewController {
    
    // MARK: - IBOutlets (스토리보드 연결 필요)
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultsTableView: UITableView!

    // MARK: - 코드로 생성할 UI
    private var emptyStateView: UIView!
    private var emptyStateLabel: UILabel!
    
    // MARK: - Properties
    var searchResults: [AudioTrack] = []
    var isSearching = false
    var searchTask: DispatchWorkItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchBar()
        setupTableView()
        createEmptyStateView() // 🆕 코드로 생성
    }
    
    // MARK: - 🆕 빈 상태 뷰를 코드로 생성
    private func createEmptyStateView() {
        // 컨테이너 뷰 생성
        emptyStateView = UIView()
        emptyStateView.backgroundColor = .systemBackground
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)
        
        // 라벨 생성
        emptyStateLabel = UILabel()
        emptyStateLabel.text = "🎵\n\nLooply와 함께 새로운 음악을\n발견해보세요"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.textColor = .systemGray2
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(emptyStateLabel)
        
        // 제약조건 설정
        NSLayoutConstraint.activate([
            // emptyStateView - TableView와 같은 위치
            emptyStateView.topAnchor.constraint(equalTo: resultsTableView.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: resultsTableView.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: resultsTableView.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: resultsTableView.bottomAnchor),
            
            // emptyStateLabel - 중앙 배치
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: emptyStateView.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: emptyStateView.trailingAnchor, constant: -40)
        ])
        
        // 줄 간격 설정
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center
        
        let attributedText = NSAttributedString(
            string: emptyStateLabel.text ?? "",
            attributes: [.paragraphStyle: paragraphStyle]
        )
        emptyStateLabel.attributedText = attributedText
        
        // 초기 상태: emptyState 보이기
        showEmptyState()
    }
    
    private func setupUI() {
        title = "음악 찾기"
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 18, weight: .medium)
        ]
        view.backgroundColor = .systemBackground
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "아티스트, 곡, 앨범을 검색해보세요 🎵"
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .clear
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor.systemGray6
            textField.layer.cornerRadius = 12
            textField.clipsToBounds = true
            textField.font = UIFont.systemFont(ofSize: 16)
        }
    }
    
    private func setupTableView() {
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        resultsTableView.backgroundColor = .clear
        resultsTableView.separatorStyle = .none
        resultsTableView.showsVerticalScrollIndicator = false
        resultsTableView.isHidden = true // 초기에는 숨김
    }
    
    // MARK: - 🔍 검색 메서드들
    private func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showEmptyState()
            return
        }
        
        // 이전 검색 취소
        searchTask?.cancel()
        
        // 새 검색 작업 생성
        searchTask = DispatchWorkItem { [weak self] in
            self?.searchSpotifyTracks(query: query)
        }
        
        // 0.5초 딜레이 후 검색 (타이핑 중 과도한 API 호출 방지)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: searchTask!)
    }
    
    private func searchSpotifyTracks(query: String) {
        isSearching = true
        
        SpotifyAPIManager.shared.searchTracks(query: query) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSearching = false
                
                switch result {
                case .success(let tracks):
                    self?.searchResults = tracks
                    self?.showResults()
                case .failure(let error):
                    print("❌ 검색 실패: \(error)")
                    self?.showErrorState()
                }
            }
        }
    }
    
    // MARK: - UI 상태 관리
    private func showEmptyState() {
        emptyStateView.isHidden = false
        resultsTableView.isHidden = true
        searchResults.removeAll()
        
        emptyStateLabel.text = "🎵\n\nLooply와 함께 새로운 음악을\n발견해보세요"
    }
    
    private func showResults() {
        emptyStateView.isHidden = true
        resultsTableView.isHidden = false
        resultsTableView.reloadData()
    }
    
    private func showErrorState() {
        emptyStateView.isHidden = false
        resultsTableView.isHidden = true
        emptyStateLabel.text = "🔍\n\n검색 중 오류가 발생했어요\n잠시 후 다시 시도해주세요"
    }
    
    // MARK: - 이미지 로딩
    private func loadImage(from url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
            }
        }.resume()
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            showEmptyState()
        } else {
            performSearch(query: searchText)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        showEmptyState()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell") ?? UITableViewCell()
        
        let track = searchResults[indexPath.row]
        
        // 기존 서브뷰 제거
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // 셀 스타일링 (감성적이고 조화롭게)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        // 컨테이너 뷰
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 2
        containerView.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(containerView)
        
        // 앨범 이미지
        let albumImageView = UIImageView()
        albumImageView.backgroundColor = .systemGray5
        albumImageView.layer.cornerRadius = 8
        albumImageView.contentMode = .scaleAspectFill
        albumImageView.clipsToBounds = true
        albumImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(albumImageView)
        
        // 곡 제목
        let titleLabel = UILabel()
        titleLabel.text = track.name
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // 아티스트명
        let artistLabel = UILabel()
        artistLabel.text = track.artist.name
        artistLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        artistLabel.textColor = .systemGray
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(artistLabel)
        
        // 앨범명
        let albumLabel = UILabel()
        albumLabel.text = track.album?.name ?? ""
        albumLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        albumLabel.textColor = .systemGray2
        albumLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(albumLabel)
        
        // 제약 조건
        NSLayoutConstraint.activate([
            // 컨테이너
            containerView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),
            containerView.heightAnchor.constraint(equalToConstant: 80),
            
            // 앨범 이미지
            albumImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            albumImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            albumImageView.widthAnchor.constraint(equalToConstant: 56),
            albumImageView.heightAnchor.constraint(equalToConstant: 56),
            
            // 곡 제목
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: albumImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            // 아티스트명
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            // 앨범명
            albumLabel.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: 2),
            albumLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            albumLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
        
        // 앨범 이미지 로드
        if let imageUrl = track.album?.imageUrl, let url = URL(string: imageUrl) {
            loadImage(from: url, into: albumImageView)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTrack = searchResults[indexPath.row]
        
        // 선택 효과
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.1, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    cell.transform = CGAffineTransform.identity
                }
            }
        }
        
        // 곡 선택 시 동작
        print("🎵 선택된 곡: \(selectedTrack.name) - \(selectedTrack.artist.name)")
        
        // TODO: 선택한 곡을 재생하거나 상세 정보 보여주기
        // 현재는 정보만 출력
    }
}
