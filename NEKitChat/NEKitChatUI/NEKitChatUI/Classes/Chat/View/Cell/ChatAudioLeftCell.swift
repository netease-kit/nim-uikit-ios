
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

class ChatAudioLeftCell: ChatBaseLeftCell,ChatAudioCell {
    var isPlaying: Bool = false
    var audioImageView = UIImageView(image: UIImage.ne_imageNamed(name: "left_play_3"))
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
            self.audioImageView.leftAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: 16),
            self.audioImageView.centerYAnchor.constraint(equalTo: bubbleImage.centerYAnchor),
            self.audioImageView.widthAnchor.constraint(equalToConstant: 28),
            self.audioImageView.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        self.timeLabel.font = UIFont.systemFont(ofSize: 14)
        self.timeLabel.textColor = UIColor.ne_darkText
        self.timeLabel.textAlignment = .left
        self.timeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.bubbleImage.addSubview(self.timeLabel)
        NSLayoutConstraint.activate([
            self.timeLabel.leftAnchor.constraint(equalTo: audioImageView.rightAnchor, constant: 12),
            self.timeLabel.centerYAnchor.constraint(equalTo: bubbleImage.centerYAnchor),
            self.timeLabel.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: -12),
            self.timeLabel.heightAnchor.constraint(equalToConstant: 28)
        ])
        self.audioImageView.animationDuration = 1
        if let leftImage1 = UIImage.ne_imageNamed(name: "left_play_1"), let leftmage2 = UIImage.ne_imageNamed(name: "left_play_2"), let leftmage3 = UIImage.ne_imageNamed(name: "left_play_3") {
            self.audioImageView.animationImages = [leftImage1,leftmage2,leftmage3]
        }
    }
    
    func startAnimation() {
        if !self.audioImageView.isAnimating {
//            self.messageModel?.audioPlaying = true
            self.audioImageView.startAnimating()
        }
    }
    
    func stopAnimation() {
        if self.audioImageView.isAnimating {
//            self.messageModel?.audioPlaying = false
            self.audioImageView.stopAnimating()
        }
    }
    
    override func setModel(_ model: MessageContentModel) {
        super.setModel(model)
        if let m  = model as? MessageAudioModel {
            self.timeLabel.text = "\(m.duration)" + "s"
            m.isPlaying ? startAnimation() : stopAnimation()
        }
    }
}
