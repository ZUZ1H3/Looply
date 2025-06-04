//
//  AlbumDetailViewController.swift
//  Looply
//
//  Created by 주지혜 on 6/4/25.
//

import UIKit

class AlbumDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var albumTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var tracksTableView: UITableView!
    
    var album: Album!
    var albumTracks: [AudioTrack] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAlbumInfo()
        fetchAlbumTracks()
    }
    
    private func setupUI() {
        // LP 스타일 디자인
        albumImageView.layer.cornerRadius = 12
        albumImageView.contentMode = .scaleAspectFill
        
        tracksTableView.delegate = self
        tracksTableView.dataSource = self
        tracksTableView.register(UITableViewCell.self, forCellReuseIdentifier: "TrackCell")
    }
    
    private func setupAlbumInfo() {
        albumTitleLabel.text = album.name
        artistNameLabel.text = album.artistName
        
        // 앨범 커버 이미지 로드
        if let imageUrl = album.imageUrl, let url = URL(string: imageUrl) {
            loadImage(from: url, into: albumImageView)
        }
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
            }
        }
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
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
        
        cell.textLabel?.text = track.name
        cell.detailTextLabel?.text = track.artist.name
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let track = albumTracks[indexPath.row]
        if let url = URL(string: track.external_urls["spotify"] ?? "") {
            UIApplication.shared.open(url)
        }
    }
}
