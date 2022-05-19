
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import UIKit
import NEKitCoreIM
import NEKitCore

protocol ChatBaseCellDelegate: AnyObject {
    func didTapAvatarView(_ cell: UITableViewCell, _ model: MessageContentModel?)
    func didTapMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?)
    func didLongPressMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?)
    func didTapResendView(_ cell: UITableViewCell, _ model: MessageContentModel?)
//     reedit button event on revokecell
    func didTapReeditButton(_ cell: UITableViewCell, _ model: MessageContentModel?)
    func didTapReadView(_ cell: UITableViewCell, _ model: MessageContentModel?)

}

class ChatBaseRightCell: ChatBaseCell {
    public var pinImage = UIImageView()
    public var avatarImage = UIImageView()
    public var nameLabel = UILabel()
    public var bubbleImage = UIImageView()
    public var activityView = ChatActivityIndicatorView()
    public var readView = CirleProgressView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
    public var seletedBtn = UIButton(type: .custom)
    public var pinLabel = UILabel()
    public var bubbleW: NSLayoutConstraint?
    public weak var delegate: ChatBaseCellDelegate?
    public var model: MessageContentModel?
    private let bubbleWidth = 32.0
    private var pinLabelW: NSLayoutConstraint?
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
        self.avatarImage.contentMode = .scaleAspectFill
        self.contentView.addSubview(self.avatarImage)
        NSLayoutConstraint.activate([
            self.avatarImage.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16),
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
        
//        bubbleImage
        self.bubbleImage.translatesAutoresizingMaskIntoConstraints = false
        if let image = UIImage.ne_imageNamed(name: "chat_message_send") {
            self.bubbleImage.image = image.resizableImage(withCapInsets: UIEdgeInsets.init(top: 35, left: 25, bottom: 10, right: 25))
        }
        self.bubbleImage.isUserInteractionEnabled = true
        self.contentView.addSubview(self.bubbleImage)
        let top = NSLayoutConstraint.init(item: self.bubbleImage, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1.0, constant: 4)
        let right = NSLayoutConstraint.init(item: self.bubbleImage, attribute: .right, relatedBy: .equal, toItem: self.avatarImage, attribute: .left, multiplier: 1.0, constant: -8)
        bubbleW = NSLayoutConstraint.init(item: self.bubbleImage, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: bubbleWidth)
        self.contentView.addConstraints([top, right])
        self.bubbleImage.addConstraint(bubbleW!)

//        activityView
        self.contentView.addSubview(activityView)
        self.activityView.translatesAutoresizingMaskIntoConstraints = false
        self.activityView.failBtn.addTarget(self, action: #selector(resend), for: .touchUpInside)
        NSLayoutConstraint.activate([
            self.activityView.rightAnchor.constraint(equalTo: self.bubbleImage.leftAnchor, constant: -8),
            self.activityView.centerYAnchor.constraint(equalTo: self.bubbleImage.centerYAnchor, constant: 0),
            self.activityView.widthAnchor.constraint(equalToConstant: 25),
            self.activityView.heightAnchor.constraint(equalToConstant: 25),
        ])
        
//        readView
        self.contentView.addSubview(readView)
        self.readView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.readView.rightAnchor.constraint(equalTo: self.bubbleImage.leftAnchor, constant: -8),
            self.readView.bottomAnchor.constraint(equalTo: self.bubbleImage.bottomAnchor, constant: 0),
            self.readView.widthAnchor.constraint(equalToConstant: 16),
            self.readView.heightAnchor.constraint(equalToConstant: 16),
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
        
        self.contentView.addSubview(pinLabel)
        self.pinLabel.translatesAutoresizingMaskIntoConstraints = false
        pinLabel.textColor = UIColor.ne_greenText
        pinLabel.font = UIFont.systemFont(ofSize: 12)
        pinLabel.textAlignment = .right
        pinLabelW = self.pinLabel.widthAnchor.constraint(equalToConstant: 210)
        pinLabelH = self.pinLabel.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            self.pinLabel.topAnchor.constraint(equalTo: self.bubbleImage.bottomAnchor, constant: 4),
            self.pinLabel.rightAnchor.constraint(equalTo: self.bubbleImage.rightAnchor, constant: 0),
            pinLabelW!,
            pinLabelH!,
            self.pinLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4),
        ])
        
        pinImage.translatesAutoresizingMaskIntoConstraints = false
        pinImage.contentMode = .scaleAspectFit
        self.contentView.addSubview(pinImage)
        NSLayoutConstraint.activate([
            pinImage.topAnchor.constraint(equalTo: self.bubbleImage.bottomAnchor, constant: 4),
            pinImage.widthAnchor.constraint(equalToConstant: 10),
            pinImage.rightAnchor.constraint(equalTo: self.pinLabel.leftAnchor, constant: -2),
            pinImage.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4),
        ])
    }
    
    func addGesture() {
//        avatar
        let tap  = UITapGestureRecognizer(target: self, action: #selector(tapAvatar))
        self.avatarImage.addGestureRecognizer(tap)
        
        let messageTap  = UITapGestureRecognizer(target: self, action: #selector(tapMessage))
        self.bubbleImage.addGestureRecognizer(messageTap)
        
        let messageLongPress  = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
//        messageLongPress.minimumPressDuration
        self.bubbleImage.addGestureRecognizer(messageLongPress)
        
        let tapReadView = UITapGestureRecognizer(target: self, action: #selector(tapReadView))
        self.readView.addGestureRecognizer(tapReadView)
        
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
    
    @objc func resend(button: UIButton) {
        print("state:default")
        self.delegate?.didTapResendView(self, self.model)
    }
    
    @objc func tapReadView(tap: UITapGestureRecognizer) {
        print(#function)
        self.delegate?.didTapReadView(self, self.model)
    }
//    MARK: set data
    func setModel(_ model: MessageContentModel) {
        self.model = model
        self.updatePinStatus(model)
        
        bubbleW?.constant = model.contentSize.width
//        print("set model width : ", model.contentSize.width)
        //avatar
        self.nameLabel.text = model.shortName
        self.avatarImage.backgroundColor = UIColor.colorWithNumber(number: UInt64(model.message?.from ?? "0"))
        if let avatarURL = model.avatar {
            self.avatarImage.sd_setImage(with: URL(string: avatarURL)) { [weak self] image, error, type, url in
                if error == nil {
                    self?.nameLabel.isHidden = true
                }else {
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
        
//        read status
//        if SettingProvider.shared.getMessageRead() && model.message?.deliveryState == .deliveried {
//            self.readView.isHidden = false
//            if model.message?.session?.sessionType == .P2P {
//                if let read = model.message?.isRemoteRead, read {
//                    readView.progress = 1
//                }else {
//                    readView.progress = 0
//                }
//            }else if model.message?.session?.sessionType == .team {
//                let  readCount = model.message?.teamReceiptInfo?.readCount ?? 0
//                let  unreadCount = model.message?.teamReceiptInfo?.unreadCount ?? 0
//                let total = Float(readCount + unreadCount)
//                if total > 0 {
//                    readView.progress = Float(readCount)/total
//                }else {
//                    readView.progress = 0
//                }
//            }
//        }else {
//            readView.isHidden = true
//        }
        
        if model.message?.deliveryState == .deliveried {
            if model.message?.session?.sessionType == .P2P {
                let receiptEnable = model.message?.setting?.teamReceiptEnabled ?? false
                if receiptEnable {
                    self.readView.isHidden = false
                    if let read = model.message?.isRemoteRead, read {
                        readView.progress = 1
                    }else {
                        readView.progress = 0
                    }
                }else {
                    self.readView.isHidden = true
                }
                
            }else if model.message?.session?.sessionType == .team {
                let receiptEnable = model.message?.setting?.teamReceiptEnabled ?? false
                if receiptEnable {
                    self.readView.isHidden = false
                    let  readCount = model.message?.teamReceiptInfo?.readCount ?? 0
                    let  unreadCount = model.message?.teamReceiptInfo?.unreadCount ?? 0
                    let total = Float(readCount + unreadCount)
                    if total > 0 {
                        readView.progress = Float(readCount)/total
                    }else {
                        readView.progress = 0
                    }
                }else {
                    readView.isHidden = true
                }
            }
        }else {
            readView.isHidden = true
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
            let size = String.getTextRectSize(self.pinLabel.text ?? localizable("pin_text"), font: UIFont.systemFont(ofSize: 11.0), size: CGSize(width: kScreenWidth - 56 - 22, height: CGFloat.greatestFiniteMagnitude))
            self.pinLabelW?.constant = size.width
            pinLabelH?.constant = chat_pin_height
        }else {
            self.pinImage.image = nil
            pinLabelH?.constant = 0
        }
    }

}
