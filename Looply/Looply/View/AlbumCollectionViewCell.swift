//
//  AlbumCollectionViewCell.swift
//  Looply
//
//  Created by 주지혜 on 6/4/25.
//

import UIKit

class AlbumCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var albumTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        // 카드 모양 만들기
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 4
        backgroundColor = .white
        
        // 앨범 이미지 LP 모양
        albumImageView.layer.cornerRadius = 8
        albumImageView.backgroundColor = .lightGray
        albumImageView.contentMode = .scaleAspectFill
    }
    
    func configure(with album: Album) {
        albumTitleLabel.text = album.name
        artistNameLabel.text = album.artistName
        
        // 기본 LP 이미지 (나중에 실제 이미지로 교체)
        albumImageView.backgroundColor = .systemGray4
    }
}
