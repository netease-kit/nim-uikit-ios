
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit
import NECoreKit
import NIMSDK
public protocol ChatBaseCellDelegate: NSObjectProtocol {
  func didTapAvatarView(_ cell: UITableViewCell, _ model: MessageContentModel?)
  func didTapMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?)
  func didLongPressMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?)
  func didTapResendView(_ cell: UITableViewCell, _ model: MessageContentModel?)
//     reedit button event on revokecell
  func didTapReeditButton(_ cell: UITableViewCell, _ model: MessageContentModel?)
  func didTapReadView(_ cell: UITableViewCell, _ model: MessageContentModel?)
}

@objcMembers
public class ChatBaseRightCell: ChatBaseCell {
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
  public var contentModel: MessageContentModel?
  private let bubbleWidth = 32.0
  private var pinLabelW: NSLayoutConstraint?
  private var pinLabelH: NSLayoutConstraint?
  private var tapGesture: UITapGestureRecognizer?

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
      avatarImage.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
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

//        bubbleImage
    bubbleImage.translatesAutoresizingMaskIntoConstraints = false
    if let image = NEKitChatConfig.shared.ui.rightBubbleBg {
      bubbleImage.image = image
        .resizableImage(withCapInsets: UIEdgeInsets(top: 35, left: 25, bottom: 10, right: 25))
    }
    bubbleImage.isUserInteractionEnabled = true
    contentView.addSubview(bubbleImage)
    let top = NSLayoutConstraint(
      item: bubbleImage,
      attribute: .top,
      relatedBy: .equal,
      toItem: contentView,
      attribute: .top,
      multiplier: 1.0,
      constant: 4
    )
    let right = NSLayoutConstraint(
      item: bubbleImage,
      attribute: .right,
      relatedBy: .equal,
      toItem: avatarImage,
      attribute: .left,
      multiplier: 1.0,
      constant: -8
    )
    bubbleW = NSLayoutConstraint(
      item: bubbleImage,
      attribute: .width,
      relatedBy: .equal,
      toItem: nil,
      attribute: .notAnAttribute,
      multiplier: 1.0,
      constant: bubbleWidth
    )
    contentView.addConstraints([top, right])
    bubbleImage.addConstraint(bubbleW!)

//        activityView
    contentView.addSubview(activityView)
    activityView.translatesAutoresizingMaskIntoConstraints = false
    activityView.failBtn.addTarget(self, action: #selector(resend), for: .touchUpInside)
    NSLayoutConstraint.activate([
      activityView.rightAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: -8),
      activityView.centerYAnchor.constraint(equalTo: bubbleImage.centerYAnchor, constant: 0),
      activityView.widthAnchor.constraint(equalToConstant: 25),
      activityView.heightAnchor.constraint(equalToConstant: 25),
    ])

//        readView
    contentView.addSubview(readView)
    readView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      readView.rightAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: -8),
      readView.bottomAnchor.constraint(equalTo: bubbleImage.bottomAnchor, constant: 0),
      readView.widthAnchor.constraint(equalToConstant: 16),
      readView.heightAnchor.constraint(equalToConstant: 16),
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

    contentView.addSubview(pinLabel)
    pinLabel.translatesAutoresizingMaskIntoConstraints = false
    pinLabel.textColor = UIColor.ne_greenText
    pinLabel.font = UIFont.systemFont(ofSize: 12)
    pinLabel.textAlignment = .right
    pinLabelW = pinLabel.widthAnchor.constraint(equalToConstant: 210)
    pinLabelH = pinLabel.heightAnchor.constraint(equalToConstant: 0)
    NSLayoutConstraint.activate([
      pinLabel.topAnchor.constraint(equalTo: bubbleImage.bottomAnchor, constant: 4),
      pinLabel.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: 0),
      pinLabelW!,
      pinLabelH!,
      pinLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
    ])

    pinImage.translatesAutoresizingMaskIntoConstraints = false
    pinImage.contentMode = .scaleAspectFit
    contentView.addSubview(pinImage)
    NSLayoutConstraint.activate([
      pinImage.topAnchor.constraint(equalTo: bubbleImage.bottomAnchor, constant: 4),
      pinImage.widthAnchor.constraint(equalToConstant: 10),
      pinImage.rightAnchor.constraint(equalTo: pinLabel.leftAnchor, constant: -2),
      pinImage.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
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
//        messageLongPress.minimumPressDuration
    bubbleImage.addGestureRecognizer(messageLongPress)

    let tapReadView = UITapGestureRecognizer(target: self, action: #selector(tapReadView))
    readView.addGestureRecognizer(tapReadView)
    tapGesture = tapReadView
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

  func resend(button: UIButton) {
    print("state:default")
    delegate?.didTapResendView(self, contentModel)
  }

  func tapReadView(tap: UITapGestureRecognizer) {
    print(#function)
    delegate?.didTapReadView(self, contentModel)
  }

//    MARK: set data

  func setModel(_ model: MessageContentModel) {
    contentModel = model
    updatePinStatus(model)
    tapGesture?.isEnabled = true
    bubbleW?.constant = model.contentSize.width
//        print("set model width : ", model.contentSize.width)
    // avatar
    nameLabel.text = model.shortName
    avatarImage.backgroundColor = UIColor
      .colorWithString(string: model.message?.from)
    if let avatarURL = model.avatar {
      avatarImage
        .sd_setImage(with: URL(string: avatarURL)) { [weak self] image, error, type, url in
          if error == nil {
            self?.nameLabel.isHidden = true
          } else {
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
      // 同一个账号，在多端登录，被对方拉黑，需要根据isBlackListed判断，进而更新信息状态
      if let isBlackMsg = model.message?.isBlackListed, isBlackMsg {
        activityView.messageStatus = .failed
      } else {
        activityView.messageStatus = .successed
      }
    case .failed:
      activityView.messageStatus = .failed
    default: break
    }

    if model.message?.deliveryState == .deliveried {
      if model.message?.session?.sessionType == .P2P {
        let receiptEnable = model.message?.setting?.teamReceiptEnabled ?? false
        if receiptEnable,
           IMKitClient.instance.repo.getShowReadStatus() == true {
          readView.isHidden = false
          if let read = model.message?.isRemoteRead, read {
            readView.progress = 1
          } else {
            readView.progress = 0
          }
          // 未读消息需要判断是否被拉黑，拉黑情况，已读未读状态不展示。
          if let isBlackMsg = model.message?.isBlackListed, isBlackMsg {
            readView.isHidden = true
          } else {
            readView.isHidden = false
          }

        } else {
          readView.isHidden = true
        }

      } else if model.message?.session?.sessionType == .team {
        let receiptEnable = model.message?.setting?.teamReceiptEnabled ?? false
        if receiptEnable,
           IMKitClient.instance.repo.getShowReadStatus() == true {
          readView.isHidden = false
          let readCount = model.message?.teamReceiptInfo?.readCount ?? 0
          let unreadCount = model.message?.teamReceiptInfo?.unreadCount ?? 0
          let total = Float(readCount + unreadCount)
          if total > 0 {
            let progress = Float(readCount) / total
            readView.progress = progress
            if progress >= 1.0 {
              tapGesture?.isEnabled = false
            }
          } else {
            readView.progress = 0
          }
        } else {
          readView.isHidden = true
        }
      }
    } else {
      readView.isHidden = true
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
      let size = String.getTextRectSize(
        pinLabel.text ?? pinText,
        font: UIFont.systemFont(ofSize: 12.0),
        size: CGSize(width: kScreenWidth - 56 - 22, height: CGFloat.greatestFiniteMagnitude)
      )
      pinLabelW?.constant = size.width + 1
      pinLabelH?.constant = chat_pin_height
    } else {
      pinImage.image = nil
      pinLabelH?.constant = 0
    }
  }
}
