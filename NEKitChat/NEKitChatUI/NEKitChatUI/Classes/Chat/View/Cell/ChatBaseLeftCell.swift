
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit

class ChatBaseLeftCell: ChatBaseCell {
    public var avatarImage = UIImageView()
    public var nameLabel = UILabel()
    public var fullNameLabel = UILabel()
    public var bubbleImage = UIImageView()
    public var activityView = ChatActivityIndicatorView()
    public var seletedBtn = UIButton(type: .custom)
    public var pinImage = UIImageView()
    public var pinLabel = UILabel()
    public var bubbleW: NSLayoutConstraint?
    public weak var delegate: ChatBaseCellDelegate?
    private let bubbleWidth = 32.0
    public var model: MessageContentModel?
    public var fullNameH: NSLayoutConstraint?
    private var pinLabelH: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        baseCommonUI()
        addGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func baseCommonUI() {
        // avatar
        self.selectionStyle = .none
        self.backgroundColor = .white
        self.avatarImage.layer.cornerRadius = 16
        self.avatarImage.backgroundColor = UIColor(hexString: "#537FF4")
        self.avatarImage.translatesAutoresizingMaskIntoConstraints = false
        self.avatarImage.clipsToBounds = true
        self.avatarImage.isUserInteractionEnabled = true
        self.contentView.addSubview(self.avatarImage)
        NSLayoutConstraint.activate([
            self.avatarImage.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            self.avatarImage.widthAnchor.constraint(equalToConstant: 32),
            self.avatarImage.heightAnchor.constraint(equalToConstant: 32),
            self.avatarImage.topAnchor.constraint(equalTo: self.topAnchor, constant: 4)
        ])
        
        // name
        self.nameLabel.textAlignment = .center
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.nameLabel.font = UIFont.systemFont(ofSize: 12)
        self.nameLabel.textColor = .white
        self.contentView.addSubview(self.nameLabel)
        NSLayoutConstraint.activate([
            self.nameLabel.leftAnchor.constraint(equalTo: self.avatarImage.leftAnchor),
            self.nameLabel.rightAnchor.constraint(equalTo: self.avatarImage.rightAnchor),
            self.nameLabel.topAnchor.constraint(equalTo: self.avatarImage.topAnchor),
            self.nameLabel.bottomAnchor.constraint(equalTo: self.avatarImage.bottomAnchor),
        ])
        
        // name
        self.fullNameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.fullNameLabel.font = UIFont.systemFont(ofSize: 12)
        self.fullNameLabel.textColor = UIColor.ne_lightText
        self.contentView.addSubview(self.fullNameLabel)
        fullNameH = self.fullNameLabel.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            self.fullNameLabel.leftAnchor.constraint(equalTo: self.avatarImage.rightAnchor, constant: 8),
            self.fullNameLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor,constant: -16),
            self.fullNameLabel.topAnchor.constraint(equalTo: self.avatarImage.topAnchor),
            fullNameH!
        ])
        
//        bubbleImage
        if let image = UIImage.ne_imageNamed(name: "chat_message_receive") {
            self.bubbleImage.image = image.resizableImage(withCapInsets: UIEdgeInsets.init(top: 35, left: 25, bottom: 10, right: 25))
        }
        self.bubbleImage.translatesAutoresizingMaskIntoConstraints = false
        self.bubbleImage.isUserInteractionEnabled = true
        self.contentView.addSubview(self.bubbleImage)
        bubbleW = self.bubbleImage.widthAnchor.constraint(equalToConstant: bubbleWidth)
        NSLayoutConstraint.activate([
            bubbleW!,
            self.bubbleImage.leftAnchor.constraint(equalTo: self.avatarImage.rightAnchor, constant: 8),
            self.bubbleImage.topAnchor.constraint(equalTo: self.fullNameLabel.bottomAnchor, constant: 0),
//            self.bubbleImage.topAnchor.constraint(equalTo: self.topAnchor, constant: 4),
        ])

//        activityView
        self.contentView.addSubview(activityView)
        self.activityView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.activityView.leftAnchor.constraint(equalTo: self.bubbleImage.rightAnchor, constant: 8),
            self.activityView.centerYAnchor.constraint(equalTo: self.bubbleImage.centerYAnchor, constant: 0),
            self.activityView.widthAnchor.constraint(equalToConstant: 25),
            self.activityView.heightAnchor.constraint(equalToConstant: 25),
        ])
        
//        seletedBtn
        self.contentView.addSubview(seletedBtn)
        self.seletedBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.seletedBtn.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            self.seletedBtn.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0),
            self.seletedBtn.widthAnchor.constraint(equalToConstant: 18),
            self.seletedBtn.heightAnchor.constraint(equalToConstant: 18),
        ])
        
//        pinImage.image = UIImage.ne_imageNamed(name: "msg_pin")
        pinImage.translatesAutoresizingMaskIntoConstraints = false
        pinImage.contentMode = .scaleAspectFit
        self.contentView.addSubview(pinImage)
        NSLayoutConstraint.activate([
            pinImage.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            pinImage.widthAnchor.constraint(equalToConstant: 10),
            pinImage.topAnchor.constraint(equalTo: self.bubbleImage.bottomAnchor, constant: 4),
            pinImage.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4),
        ])
        
        self.contentView.addSubview(pinLabel)
        self.pinLabel.translatesAutoresizingMaskIntoConstraints = false
        pinLabel.textAlignment = .left
//        pinLabel.text = localizable("pin_text")
        pinLabel.font = UIFont.systemFont(ofSize: 12)
        pinLabel.textColor = UIColor.ne_greenText
        pinLabel.isHidden = true
        pinLabelH = self.pinLabel.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            self.pinLabel.topAnchor.constraint(equalTo: self.bubbleImage.bottomAnchor, constant: 4),
            self.pinLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16),
            self.pinLabel.leftAnchor.constraint(equalTo: pinImage.rightAnchor, constant: 2),
            pinLabelH!,
            self.pinLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4),
        ])
    }
    
    func addGesture() {
//        avatar
        let tap  = UITapGestureRecognizer(target: self, action: #selector(tapAvatar))
        self.avatarImage.addGestureRecognizer(tap)
        
        let messageTap  = UITapGestureRecognizer(target: self, action: #selector(tapMessage))
        self.bubbleImage.addGestureRecognizer(messageTap)
        
        let messageLongPress  = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        self.bubbleImage.addGestureRecognizer(messageLongPress)
    }
    
//    MARK: event
    @objc func tapAvatar(tap: UITapGestureRecognizer) {
        print(#function)
        self.delegate?.didTapAvatarView(self, self.model)
    }
    
    @objc func tapMessage(tap: UITapGestureRecognizer) {
        print(#function)
        self.delegate?.didTapMessageView(self, self.model)
    }
    
    @objc func longPress(longPress: UILongPressGestureRecognizer) {
        print(#function)
        switch longPress.state {
        case .began:
            print("state:begin")
            self.delegate?.didLongPressMessageView(self, self.model)
        case .changed:
            print("state:changed")
        case .ended:
            print("state:ended")
        case .cancelled:
            print("state:cancelled")
        case .failed:
            print("state:failed")
        default:
            print("state:default")
        }
    }
    
//    MARK: set data
    func setModel(_ model: MessageContentModel) {
        self.model = model
        self.updatePinStatus(model)
        bubbleW?.constant = model.contentSize.width
        //avatar
        self.nameLabel.text = model.shortName
        if model.fullNameHeight > 0 {
            self.fullNameLabel.text = model.fullName
            self.fullNameLabel.isHidden = false
        }else {
            self.fullNameLabel.text = nil
            self.fullNameLabel.isHidden = true
        }
        fullNameH?.constant = CGFloat(model.fullNameHeight)
        self.avatarImage.backgroundColor = UIColor.colorWithNumber(number: UInt64(model.message?.from ?? "0"))
        if let avatarURL = model.avatar {
            self.avatarImage.sd_setImage(with: URL(string: avatarURL)) { [weak self] image, error, type, url in
                if image != nil {
                    self?.avatarImage.image = image
                    self?.nameLabel.isHidden = true
                }else {
                    self?.avatarImage.image = nil
                    self?.nameLabel.isHidden = false
                }
            }
        }else {
            self.avatarImage.image = nil
            self.nameLabel.isHidden = false
        }
        switch model.message?.deliveryState {
        case .delivering:
            self.activityView.messageStatus = .sending
        case .deliveried:
            self.activityView.messageStatus = .successed
        case .failed:
            self.activityView.messageStatus = .failed
        default: break
        }
    }
    
    private func updatePinStatus(_ model: MessageContentModel) {
        self.pinLabel.isHidden = !model.isPined
        self.pinImage.isHidden = !model.isPined
        self.contentView.backgroundColor = model.isPined ? UIColor.ne_yellowBackgroundColor : .white
        if model.isPined {
            if let text = model.pinShowName {
                self.pinLabel.text = text + localizable("pin_text")
            }
            self.pinImage.image = UIImage.ne_imageNamed(name: "msg_pin")
            pinLabelH?.constant = chat_pin_height

        }else {
            self.pinImage.image = nil
            pinLabelH?.constant = 0

        }
    }
}
