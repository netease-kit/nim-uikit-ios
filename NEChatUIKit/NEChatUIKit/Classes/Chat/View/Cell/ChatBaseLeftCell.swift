
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK
@objcMembers
public class ChatBaseLeftCell: ChatBaseCell {
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
  public var contentModel: MessageContentModel?
  public var fullNameH: NSLayoutConstraint?
  private var pinLabelH: NSLayoutConstraint?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    baseCommonUI()
    addGesture()
    initSubviewsLayout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func baseCommonUI() {
    // avatar
    selectionStyle = .none
    backgroundColor = .white
    avatarImage.layer.cornerRadius = 16
    avatarImage.backgroundColor = UIColor(hexString: "#537FF4")
    avatarImage.translatesAutoresizingMaskIntoConstraints = false
    avatarImage.clipsToBounds = true
    avatarImage.isUserInteractionEnabled = true
    avatarImage.contentMode = .scaleAspectFill
    contentView.addSubview(avatarImage)
    NSLayoutConstraint.activate([
      avatarImage.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
      avatarImage.widthAnchor.constraint(equalToConstant: 32),
      avatarImage.heightAnchor.constraint(equalToConstant: 32),
      avatarImage.topAnchor.constraint(equalTo: topAnchor, constant: 4),
    ])

    // name
    nameLabel.textAlignment = .center
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.font = UIFont.systemFont(ofSize: 12)
    nameLabel.textColor = .white
    contentView.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: avatarImage.leftAnchor),
      nameLabel.rightAnchor.constraint(equalTo: avatarImage.rightAnchor),
      nameLabel.topAnchor.constraint(equalTo: avatarImage.topAnchor),
      nameLabel.bottomAnchor.constraint(equalTo: avatarImage.bottomAnchor),
    ])

    // name
    fullNameLabel.translatesAutoresizingMaskIntoConstraints = false
    fullNameLabel.font = UIFont.systemFont(ofSize: 12)
    fullNameLabel.textColor = UIColor.ne_lightText
    contentView.addSubview(fullNameLabel)
    fullNameH = fullNameLabel.heightAnchor.constraint(equalToConstant: 0)
    NSLayoutConstraint.activate([
      fullNameLabel.leftAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: 8),
      fullNameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
      fullNameLabel.topAnchor.constraint(equalTo: avatarImage.topAnchor),
      fullNameH!,
    ])

//        bubbleImage
    if let image = NEKitChatConfig.shared.ui.leftBubbleBg {
      bubbleImage.image = image
        .resizableImage(withCapInsets: UIEdgeInsets(top: 35, left: 25, bottom: 10, right: 25))
    }
    bubbleImage.translatesAutoresizingMaskIntoConstraints = false
    bubbleImage.isUserInteractionEnabled = true
    contentView.addSubview(bubbleImage)
    bubbleW = bubbleImage.widthAnchor.constraint(equalToConstant: bubbleWidth)
    NSLayoutConstraint.activate([
      bubbleW!,
      bubbleImage.leftAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: 8),
      bubbleImage.topAnchor.constraint(equalTo: fullNameLabel.bottomAnchor, constant: 0),
//            self.bubbleImage.topAnchor.constraint(equalTo: self.topAnchor, constant: 4),
    ])

//        activityView
    contentView.addSubview(activityView)
    activityView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      activityView.leftAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: 8),
      activityView.centerYAnchor.constraint(equalTo: bubbleImage.centerYAnchor, constant: 0),
      activityView.widthAnchor.constraint(equalToConstant: 25),
      activityView.heightAnchor.constraint(equalToConstant: 25),
    ])

//        seletedBtn
    contentView.addSubview(seletedBtn)
    seletedBtn.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      seletedBtn.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
      seletedBtn.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
      seletedBtn.widthAnchor.constraint(equalToConstant: 18),
      seletedBtn.heightAnchor.constraint(equalToConstant: 18),
    ])

//        pinImage.image = UIImage.ne_imageNamed(name: "msg_pin")
    pinImage.translatesAutoresizingMaskIntoConstraints = false
    pinImage.contentMode = .scaleAspectFit
    contentView.addSubview(pinImage)
    NSLayoutConstraint.activate([
      pinImage.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
      pinImage.widthAnchor.constraint(equalToConstant: 10),
      pinImage.topAnchor.constraint(equalTo: bubbleImage.bottomAnchor, constant: 4),
      pinImage.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
    ])

    contentView.addSubview(pinLabel)
    pinLabel.translatesAutoresizingMaskIntoConstraints = false
    pinLabel.textAlignment = .left
    pinLabel.font = UIFont.systemFont(ofSize: 12)
    pinLabel.textColor = UIColor.ne_greenText
    pinLabel.isHidden = true
    pinLabelH = pinLabel.heightAnchor.constraint(equalToConstant: 0)

    NSLayoutConstraint.activate([
      pinLabel.topAnchor.constraint(equalTo: bubbleImage.bottomAnchor, constant: 4),
      pinLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
      pinLabel.leftAnchor.constraint(equalTo: pinImage.rightAnchor, constant: 2),
      pinLabelH!,
      pinLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
    ])
  }

  func addGesture() {
//        avatar
    let tap = UITapGestureRecognizer(target: self, action: #selector(tapAvatar))
    avatarImage.addGestureRecognizer(tap)

    let messageTap = UITapGestureRecognizer(target: self, action: #selector(tapMessage))
    bubbleImage.addGestureRecognizer(messageTap)

    let messageLongPress = UILongPressGestureRecognizer(
      target: self,
      action: #selector(longPress)
    )
    bubbleImage.addGestureRecognizer(messageLongPress)
  }

  func initSubviewsLayout() {
    if NEKitChatConfig.shared.ui.avatarType == .rectangle {
      avatarImage.layer.cornerRadius = NEKitChatConfig.shared.ui.avatarCornerRadius
    } else if NEKitChatConfig.shared.ui.avatarType == .cycle {
      avatarImage.layer.cornerRadius = 16.0
    }
  }

//    MARK: event

  func tapAvatar(tap: UITapGestureRecognizer) {
    print(#function)
    delegate?.didTapAvatarView(self, contentModel)
  }

  func tapMessage(tap: UITapGestureRecognizer) {
    print(#function)
    delegate?.didTapMessageView(self, contentModel)
  }

  func longPress(longPress: UILongPressGestureRecognizer) {
    print(#function)
    switch longPress.state {
    case .began:
      print("state:begin")
      delegate?.didLongPressMessageView(self, contentModel)
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
    contentModel = model
    updatePinStatus(model)
    bubbleW?.constant = model.contentSize.width
    // avatar
    nameLabel.text = model.shortName
    if model.fullNameHeight > 0 {
      fullNameLabel.text = model.fullName
      fullNameLabel.isHidden = false
    } else {
      fullNameLabel.text = nil
      fullNameLabel.isHidden = true
    }
    fullNameH?.constant = CGFloat(model.fullNameHeight)
    avatarImage.backgroundColor = UIColor
      .colorWithString(string: model.message?.from)
    if let avatarURL = model.avatar {
      avatarImage
        .sd_setImage(with: URL(string: avatarURL)) { [weak self] image, error, type, url in
          if image != nil {
            self?.avatarImage.image = image
            self?.nameLabel.isHidden = true
          } else {
            self?.avatarImage.image = nil
            self?.nameLabel.isHidden = false
          }
        }
    } else {
      avatarImage.image = nil
      nameLabel.isHidden = false
    }
    switch model.message?.deliveryState {
    case .delivering:
      activityView.messageStatus = .sending
    case .deliveried:
      activityView.messageStatus = .successed
    case .failed:
      activityView.messageStatus = .failed
    default: break
    }
  }

  private func updatePinStatus(_ model: MessageContentModel) {
    pinLabel.isHidden = !model.isPined
    pinImage.isHidden = !model.isPined
    contentView.backgroundColor = model.isPined ? NEKitChatConfig.shared.ui
      .chatPinColor : .white
    if model.isPined {
      let pinText = model.message?.session?.sessionType == .P2P ? chatLocalizable("pin_text_P2P") : chatLocalizable("pin_text_team")
      if model.pinAccount == nil {
        pinLabel.text = chatLocalizable("You") + pinText
      } else if let account = model.pinAccount, account == NIMSDK.shared().loginManager.currentAccount() {
        pinLabel.text = chatLocalizable("You") + pinText
      } else if let text = model.pinShowName {
        pinLabel.text = text + pinText
      }

      pinImage.image = UIImage.ne_imageNamed(name: "msg_pin")
      pinLabelH?.constant = chat_pin_height

    } else {
      pinImage.image = nil
      pinLabelH?.constant = 0
    }
  }
}
