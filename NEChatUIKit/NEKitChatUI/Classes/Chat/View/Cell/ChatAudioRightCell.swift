
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

protocol ChatAudioCell {
    var isPlaying: Bool  { get set }
    func startAnimation()
    func stopAnimation()
}

class ChatAudioRightCell: ChatBaseRightCell,ChatAudioCell {
    var isPlaying: Bool = false
    var audioImageView = UIImageView(image: UIImage.ne_imageNamed(name: "audio_play"))
    var timeLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonUI() {
        self.audioImageView.contentMode = .center
        self.audioImageView.translatesAutoresizingMaskIntoConstraints = false
        self.bubbleImage.addSubview(self.audioImageView)
        NSLayoutConstraint.activate([
            self.audioImageView.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: -16),
            self.audioImageView.centerYAnchor.constraint(equalTo: bubbleImage.centerYAnchor),
            self.audioImageView.widthAnchor.constraint(equalToConstant: 28),
            self.audioImageView.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        self.timeLabel.font = UIFont.systemFont(ofSize: 14)
        self.timeLabel.textColor = UIColor.ne_darkText
        self.timeLabel.textAlignment = .right
        self.timeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.bubbleImage.addSubview(self.timeLabel)
        NSLayoutConstraint.activate([
            self.timeLabel.rightAnchor.constraint(equalTo: audioImageView.leftAnchor, constant: -12),
            self.timeLabel.centerYAnchor.constraint(equalTo: bubbleImage.centerYAnchor),
            self.timeLabel.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        self.audioImageView.animationDuration = 1
        if let image1 = UIImage.ne_imageNamed(name: "play_1"), let image2 = UIImage.ne_imageNamed(name: "play_2"), let image3 = UIImage.ne_imageNamed(name: "play_3") {
            self.audioImageView.animationImages = [image1,image2,image3]
        }
    }
    
    func startAnimation() {
        if !self.audioImageView.isAnimating {
            self.audioImageView.startAnimating()
            if let m = model as? MessageAudioModel {
                m.isPlaying = true
                self.isPlaying = true
            }
        }
    }
    
    func stopAnimation() {
        if self.audioImageView.isAnimating {
            self.audioImageView.stopAnimating()
            if let m = model as? MessageAudioModel {
                m.isPlaying = false
                self.isPlaying = false
            }
        }
    }
    
    override func setModel(_ model: MessageContentModel) {
        super.setModel(model)
        if let m = model as? MessageAudioModel {
            self.timeLabel.text = "\(m.duration)" + "s"
            m.isPlaying ? startAnimation() : stopAnimation()
        }
    }
}
