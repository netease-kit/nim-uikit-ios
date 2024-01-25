
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import NECoreKit
import NIMSDK
import UIKit

@objc
public protocol ChatBaseCellDelegate: NSObjectProtocol {
  // 单击头像
  func didTapAvatarView(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 长按头像
  func didLongPressAvatar(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 单击消息体
  func didTapMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 长按消息体
  func didLongPressMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 单击重发按钮
  func didTapResendView(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 单击重新编辑按钮
  func didTapReeditButton(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 单击已读未读按钮
  func didTapReadView(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 单击多选按钮
  func didTapSelectButton(_ cell: UITableViewCell, _ model: MessageContentModel?)
}

@objc
protocol ChatAudioCellProtocol {
  var isPlaying: Bool { get set }
  var messageId: String? { get set }
  func startAnimation(byRight: Bool)
  func stopAnimation(byRight: Bool)
}

@objcMembers
open class NEBaseChatMessageCell: NEChatBaseCell {
  private let bubbleWidth: CGFloat = 218 // 气泡默认宽度
  private let pinLabelMaxWidth: CGFloat = 280 // pin 文案最大宽度
  public weak var delegate: ChatBaseCellDelegate?
  public var contentModel: MessageContentModel? // 消息模型

  /// Left
  public var avatarImageLeft = UIImageView() // 左侧头像
  public var avatarImageLeftAnchor: NSLayoutConstraint? // 左侧头像左侧布局依赖
  public var nameLabelLeft = UILabel() // 左侧头像文字（无头像预设）
  public var bubbleImageLeft = UIImageView() // 左侧气泡
  public var bubbleTopAnchorLeft: NSLayoutConstraint? // 左侧气泡顶部布局约束
  public var bubbleWLeft: NSLayoutConstraint? // 左侧气泡宽度布局约束
  public var bubbleHLeft: NSLayoutConstraint? // 左侧气泡高度布局约束
  public var pinImageLeft = UIImageView() // 左侧标记图片
  public var pinLabelLeft = UILabel() // 左侧标记文案
  public var pinLabelLeftTopAnchor: NSLayoutConstraint? // 左侧标记文案顶部布局约束
  private var pinLabelHLeft: NSLayoutConstraint? // 左侧标记文案宽度布局约束
  private var pinLabelWLeft: NSLayoutConstraint? // 左侧标记文案高度布局约束
  public var fullNameLabel = UILabel() // 群昵称（只在群聊中有效）
  public var fullNameH: NSLayoutConstraint? // 群昵称高度布局约束

  /// Right
  public var avatarImageRight = UIImageView() // 右侧头像
  public var nameLabelRight = UILabel() // 右侧头像文字（无头像预设）
  public var bubbleImageRight = UIImageView() // 右侧气泡
  public var bubbleWRight: NSLayoutConstraint? // 右侧气泡宽度布局约束
  public var bubbleHRight: NSLayoutConstraint? // 右侧气泡高度布局约束
  public var pinImageRight = UIImageView() // 右侧标记图片
  public var pinLabelRight = UILabel() // 右侧标记文案
  public var pinLabelRightTopAnchor: NSLayoutConstraint? // 右侧标记文案顶部布局约束
  private var pinLabelHRight: NSLayoutConstraint? // 右侧标记文案宽度布局约束
  private var pinLabelWRight: NSLayoutConstraint? // 右侧标记文案高度布局约束

  // 已读未读视图
  public var readView = CirleProgressView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
  public var activityView = ChatActivityIndicatorView() // 消息状态视图
  public var seletedBtn = UIButton(type: .custom) // 多选按钮
  public var timeLabel = UILabel() // 消息时间
  public var timeLabelHeightAnchor: NSLayoutConstraint? // 消息时间高度约束

  // 已读未读点击手势
  private var tapGesture: UITapGestureRecognizer?

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    initProperty()
    baseCommonUI()
    addGesture()
    initSubviewsLayout()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    gestureRecognizers?.forEach { gestrue in
      removeGestureRecognizer(gestrue)
    }
  }

  open func initProperty() {
    timeLabel.font = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.timeTextSize)
    timeLabel.textColor = NEKitChatConfig.shared.ui.messageProperties.timeTextColor
    timeLabel.textAlignment = .center
    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    timeLabel.accessibilityIdentifier = "id.messageTipText"
    timeLabel.backgroundColor = .white

    // avatar
    avatarImageLeft.backgroundColor = UIColor(hexString: "#537FF4")
    avatarImageLeft.translatesAutoresizingMaskIntoConstraints = false
    avatarImageLeft.clipsToBounds = true
    avatarImageLeft.isUserInteractionEnabled = true
    avatarImageLeft.contentMode = .scaleAspectFill
    avatarImageLeft.accessibilityIdentifier = "id.avatar"

    avatarImageRight.backgroundColor = UIColor(hexString: "#537FF4")
    avatarImageRight.translatesAutoresizingMaskIntoConstraints = false
    avatarImageRight.clipsToBounds = true
    avatarImageRight.isUserInteractionEnabled = true
    avatarImageRight.contentMode = .scaleAspectFill
    avatarImageRight.accessibilityIdentifier = "id.avatar"

    // name
    nameLabelLeft.textAlignment = .center
    nameLabelLeft.translatesAutoresizingMaskIntoConstraints = false
    nameLabelLeft.font = UIFont.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.userNickTextSize)
    nameLabelLeft.textColor = NEKitChatConfig.shared.ui.messageProperties.userNickColor

    nameLabelRight.textAlignment = .center
    nameLabelRight.translatesAutoresizingMaskIntoConstraints = false
    nameLabelRight.font = UIFont.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.userNickTextSize)
    nameLabelRight.textColor = NEKitChatConfig.shared.ui.messageProperties.userNickColor

    // fullName
    fullNameLabel.translatesAutoresizingMaskIntoConstraints = false
    fullNameLabel.font = UIFont.systemFont(ofSize: 12)
    fullNameLabel.textColor = UIColor.ne_lightText
    fullNameLabel.accessibilityIdentifier = "id.fullNameLabel"

    //        bubbleImage
    bubbleImageLeft.backgroundColor = NEKitChatConfig.shared.ui.messageProperties.receiveMessageBg
    var image = NEKitChatConfig.shared.ui.messageProperties.leftBubbleBg ?? UIImage.ne_imageNamed(name: "chat_message_receive")
    bubbleImageLeft.image = image?
      .resizableImage(withCapInsets: NEKitChatConfig.shared.ui.messageProperties.backgroundImageCapInsets)
    bubbleImageLeft.translatesAutoresizingMaskIntoConstraints = false
    bubbleImageLeft.isUserInteractionEnabled = true

    bubbleImageRight.backgroundColor = NEKitChatConfig.shared.ui.messageProperties.selfMessageBg
    image = NEKitChatConfig.shared.ui.messageProperties.rightBubbleBg ?? UIImage.ne_imageNamed(name: "chat_message_send")
    bubbleImageRight.image = image?
      .resizableImage(withCapInsets: NEKitChatConfig.shared.ui.messageProperties.backgroundImageCapInsets)
    bubbleImageRight.translatesAutoresizingMaskIntoConstraints = false
    bubbleImageRight.isUserInteractionEnabled = true

    pinLabelLeft.translatesAutoresizingMaskIntoConstraints = false
    pinLabelLeft.textColor = UIColor.ne_greenText
    pinLabelLeft.font = UIFont.systemFont(ofSize: 12)
    pinLabelLeft.textAlignment = .left
    pinLabelLeft.lineBreakMode = .byTruncatingMiddle
    pinLabelLeft.accessibilityIdentifier = "id.signal"

    pinLabelRight.translatesAutoresizingMaskIntoConstraints = false
    pinLabelRight.textColor = UIColor.ne_greenText
    pinLabelRight.font = UIFont.systemFont(ofSize: 12)
    pinLabelRight.textAlignment = .right
    pinLabelRight.lineBreakMode = .byTruncatingMiddle
    pinLabelRight.accessibilityIdentifier = "id.signal"

    pinImageLeft.translatesAutoresizingMaskIntoConstraints = false
    pinImageLeft.contentMode = .scaleAspectFit

    pinImageRight.translatesAutoresizingMaskIntoConstraints = false
    pinImageRight.contentMode = .scaleAspectFit

    readView.translatesAutoresizingMaskIntoConstraints = false
    readView.accessibilityIdentifier = "id.readView"

    activityView.accessibilityIdentifier = "id.status"

    seletedBtn.translatesAutoresizingMaskIntoConstraints = false
    seletedBtn.setImage(.ne_imageNamed(name: "unselect"), for: .normal)
    seletedBtn.setImage(.ne_imageNamed(name: "select"), for: .selected)
    seletedBtn.addTarget(self, action: #selector(selectButtonClicked), for: .touchUpInside)
  }

  open func baseCommonUI() {
    selectionStyle = .none
    backgroundColor = .clear

    // time
    contentView.addSubview(timeLabel)
    timeLabelHeightAnchor = timeLabel.heightAnchor.constraint(equalToConstant: chat_timeCellH)
    NSLayoutConstraint.activate([
      timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
      timeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
      timeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -0),
      timeLabelHeightAnchor!,
    ])

    baseCommonUILeft()
    baseCommonUIRight()
  }

  open func baseCommonUILeft() {
    contentView.addSubview(avatarImageLeft)
    avatarImageLeftAnchor = avatarImageLeft.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16)
    NSLayoutConstraint.activate([
      avatarImageLeft.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: chat_content_margin),
      avatarImageLeftAnchor!,
      avatarImageLeft.widthAnchor.constraint(equalToConstant: 32),
      avatarImageLeft.heightAnchor.constraint(equalToConstant: 32),
    ])

    contentView.addSubview(nameLabelLeft)
    NSLayoutConstraint.activate([
      nameLabelLeft.leftAnchor.constraint(equalTo: avatarImageLeft.leftAnchor),
      nameLabelLeft.rightAnchor.constraint(equalTo: avatarImageLeft.rightAnchor),
      nameLabelLeft.topAnchor.constraint(equalTo: avatarImageLeft.topAnchor),
      nameLabelLeft.bottomAnchor.constraint(equalTo: avatarImageLeft.bottomAnchor),
    ])

    contentView.addSubview(fullNameLabel)
    fullNameH = fullNameLabel.heightAnchor.constraint(equalToConstant: 0)
    NSLayoutConstraint.activate([
      fullNameLabel.leftAnchor.constraint(equalTo: avatarImageLeft.rightAnchor, constant: chat_content_margin),
      fullNameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
      fullNameLabel.topAnchor.constraint(equalTo: avatarImageLeft.topAnchor),
      fullNameH!,
    ])

    //  bubbleImageLeft
    contentView.addSubview(bubbleImageLeft)
    bubbleTopAnchorLeft = bubbleImageLeft.topAnchor.constraint(equalTo: fullNameLabel.bottomAnchor, constant: 0)
    bubbleWLeft = bubbleImageLeft.widthAnchor.constraint(equalToConstant: bubbleWidth)
    bubbleHLeft = bubbleImageLeft.heightAnchor.constraint(equalToConstant: bubbleWidth)
    NSLayoutConstraint.activate([
      bubbleTopAnchorLeft!,
      bubbleImageLeft.leftAnchor.constraint(equalTo: avatarImageLeft.rightAnchor, constant: chat_content_margin),
      bubbleWLeft!,
      bubbleHLeft!,
    ])

    contentView.addSubview(pinLabelLeft)
    pinLabelLeftTopAnchor = pinLabelLeft.topAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: 4)
    pinLabelHLeft = pinLabelLeft.heightAnchor.constraint(equalToConstant: 0)
    pinLabelWLeft = pinLabelLeft.widthAnchor.constraint(equalToConstant: pinLabelMaxWidth)
    NSLayoutConstraint.activate([
      pinLabelLeftTopAnchor!,
      pinLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: 14),
      pinLabelWLeft!,
      pinLabelHLeft!,
    ])

    contentView.addSubview(pinImageLeft)
    NSLayoutConstraint.activate([
      pinImageLeft.rightAnchor.constraint(equalTo: pinLabelLeft.leftAnchor, constant: -2),
      pinImageLeft.widthAnchor.constraint(equalToConstant: 10),
      pinImageLeft.centerYAnchor.constraint(equalTo: pinLabelLeft.centerYAnchor),
    ])
  }

  open func baseCommonUIRight() {
    contentView.addSubview(avatarImageRight)
    NSLayoutConstraint.activate([
      avatarImageRight.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
      avatarImageRight.widthAnchor.constraint(equalToConstant: 32),
      avatarImageRight.heightAnchor.constraint(equalToConstant: 32),
      avatarImageRight.topAnchor.constraint(equalTo: avatarImageLeft.topAnchor, constant: 0),
    ])

    contentView.addSubview(nameLabelRight)
    NSLayoutConstraint.activate([
      nameLabelRight.leftAnchor.constraint(equalTo: avatarImageRight.leftAnchor),
      nameLabelRight.rightAnchor.constraint(equalTo: avatarImageRight.rightAnchor),
      nameLabelRight.topAnchor.constraint(equalTo: avatarImageRight.topAnchor),
      nameLabelRight.bottomAnchor.constraint(equalTo: avatarImageRight.bottomAnchor),
    ])

    contentView.addSubview(bubbleImageRight)
    bubbleWRight = bubbleImageRight.widthAnchor.constraint(equalToConstant: bubbleWidth)
    bubbleHRight = bubbleImageRight.heightAnchor.constraint(equalToConstant: bubbleWidth)
    NSLayoutConstraint.activate([
      bubbleImageRight.topAnchor.constraint(equalTo: avatarImageRight.topAnchor, constant: 0),
      bubbleImageRight.rightAnchor.constraint(equalTo: avatarImageRight.leftAnchor, constant: -chat_content_margin),
      bubbleWRight!,
      bubbleHRight!,
    ])

//        activityView
    contentView.addSubview(activityView)
    activityView.translatesAutoresizingMaskIntoConstraints = false
    activityView.failBtn.addTarget(self, action: #selector(resend), for: .touchUpInside)
    NSLayoutConstraint.activate([
      activityView.rightAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: -chat_content_margin),
      activityView.centerYAnchor.constraint(equalTo: bubbleImageRight.centerYAnchor, constant: 0),
      activityView.widthAnchor.constraint(equalToConstant: 25),
      activityView.heightAnchor.constraint(equalToConstant: 25),
    ])

//        readView
    contentView.addSubview(readView)
    NSLayoutConstraint.activate([
      readView.rightAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: -chat_content_margin),
      readView.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: 0),
      readView.widthAnchor.constraint(equalToConstant: 16),
      readView.heightAnchor.constraint(equalToConstant: 16),
    ])

//        seletedBtn
    contentView.addSubview(seletedBtn)
    NSLayoutConstraint.activate([
      seletedBtn.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      seletedBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
      seletedBtn.widthAnchor.constraint(equalToConstant: 18),
      seletedBtn.heightAnchor.constraint(equalToConstant: 18),
    ])

    contentView.addSubview(pinLabelRight)
    pinLabelRightTopAnchor = pinLabelRight.topAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: 4)
    pinLabelHRight = pinLabelRight.heightAnchor.constraint(equalToConstant: 0)
    pinLabelWRight = pinLabelRight.widthAnchor.constraint(equalToConstant: 210)
    NSLayoutConstraint.activate([
      pinLabelRightTopAnchor!,
      pinLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: 0),
      pinLabelWRight!,
      pinLabelHRight!,
    ])

    contentView.addSubview(pinImageRight)
    NSLayoutConstraint.activate([
      pinImageRight.rightAnchor.constraint(equalTo: pinLabelRight.leftAnchor, constant: -2),
      pinImageRight.centerYAnchor.constraint(equalTo: pinLabelRight.centerYAnchor),
      pinImageRight.widthAnchor.constraint(equalToConstant: 10),
    ])
  }

  open func addGesture() {
//        avatar
    let avatarTapRight = UITapGestureRecognizer(target: self, action: #selector(tapAvatar))
    avatarTapRight.cancelsTouchesInView = false
    avatarImageRight.addGestureRecognizer(avatarTapRight)
    let avatarTapLeft = UITapGestureRecognizer(target: self, action: #selector(tapAvatar))
    avatarTapLeft.cancelsTouchesInView = false
    avatarImageLeft.addGestureRecognizer(avatarTapLeft)

    let avatarLongGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressAvatar))
    avatarLongGesture.cancelsTouchesInView = false
    avatarImageLeft.addGestureRecognizer(avatarLongGesture)

    let messageTapRight = UITapGestureRecognizer(target: self, action: #selector(tapMessage))
    messageTapRight.cancelsTouchesInView = false
    bubbleImageRight.addGestureRecognizer(messageTapRight)
    let messageTapLeft = UITapGestureRecognizer(target: self, action: #selector(tapMessage))
    messageTapLeft.cancelsTouchesInView = false
    bubbleImageLeft.addGestureRecognizer(messageTapLeft)

    let messageLongPressRight = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    bubbleImageRight.addGestureRecognizer(messageLongPressRight)
    let messageLongPressLeft = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    bubbleImageLeft.addGestureRecognizer(messageLongPressLeft)

    let tapReadView = UITapGestureRecognizer(target: self, action: #selector(tapReadView))
    tapReadView.cancelsTouchesInView = false
    readView.addGestureRecognizer(tapReadView)
    tapGesture = tapReadView
  }

  open func initSubviewsLayout() {
    if NEKitChatConfig.shared.ui.messageProperties.avatarType == .rectangle,
       NEKitChatConfig.shared.ui.messageProperties.avatarCornerRadius > 0 {
      avatarImageRight.layer.cornerRadius = NEKitChatConfig.shared.ui.messageProperties.avatarCornerRadius
      avatarImageLeft.layer.cornerRadius = NEKitChatConfig.shared.ui.messageProperties.avatarCornerRadius
    } else if NEKitChatConfig.shared.ui.messageProperties.avatarType == .cycle {
      avatarImageRight.layer.cornerRadius = 16.0
      avatarImageLeft.layer.cornerRadius = 16.0
    } else {
      avatarImageRight.layer.cornerRadius = 16.0
      avatarImageLeft.layer.cornerRadius = 16.0
    }
  }

//    MARK: event

  open func tapAvatar(tap: UITapGestureRecognizer) {
    print(#function)
    delegate?.didTapAvatarView(self, contentModel)
  }

  open func tapMessage(tap: UITapGestureRecognizer) {
    print(#function)
    delegate?.didTapMessageView(self, contentModel)
  }

  open func longPressAvatar(longPress: UITapGestureRecognizer) {
    if longPress.state == .began {
      delegate?.didLongPressAvatar(self, contentModel)
    }
  }

  open func longPress(longPress: UILongPressGestureRecognizer) {
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

  open func resend(button: UIButton) {
    print("state:default")
    delegate?.didTapResendView(self, contentModel)
  }

  open func tapReadView(tap: UITapGestureRecognizer) {
    print(#function)
    delegate?.didTapReadView(self, contentModel)
  }

  open func selectButtonClicked() {
    seletedBtn.isSelected = !seletedBtn.isSelected
    if let model = contentModel {
      model.isSelected = !model.isSelected
    }
    delegate?.didTapSelectButton(self, contentModel)
  }

//    MARK: set data

  open func setSelect(_ model: MessageContentModel, _ enableSelect: Bool = false) {
    // 多选框
    seletedBtn.isHidden = model.isRevoked || !enableSelect
    seletedBtn.isSelected = model.isSelected
    avatarImageLeftAnchor?.constant = enableSelect ? 42 : 16
  }

  override open func setModel(_ model: MessageContentModel) {
    setModel(model, model.message?.isOutgoingMsg ?? false)
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    let bubbleW = isSend ? bubbleWRight : bubbleWLeft
    let bubbleH = isSend ? bubbleHRight : bubbleHLeft
    let nameLabel = isSend ? nameLabelRight : nameLabelLeft
    let avatarImage = isSend ? avatarImageRight : avatarImageLeft

    contentModel = model
    tapGesture?.isEnabled = true
    showLeftOrRight(showRight: isSend)
    updatePinStatus(model)

    // time
    if let time = model.timeContent, !time.isEmpty {
      timeLabelHeightAnchor?.constant = chat_timeCellH
      timeLabel.text = time
      timeLabel.isHidden = false
    } else {
      timeLabelHeightAnchor?.constant = 0
      timeLabel.text = ""
      timeLabel.isHidden = true
    }

    bubbleW?.constant = model.contentSize.width
    bubbleH?.constant = model.contentSize.height

    // avatar
    nameLabel.text = model.shortName
    if let avatarURL = model.avatar, !avatarURL.isEmpty {
      avatarImage
        .sd_setImage(with: URL(string: avatarURL)) { image, error, type, url in
          if image != nil {
            avatarImage.image = image
            nameLabel.isHidden = true
            avatarImage.backgroundColor = .clear
          } else {
            avatarImage.image = nil
            nameLabel.isHidden = false
            avatarImage.backgroundColor = UIColor
              .colorWithString(string: model.message?.from)
          }
        }
    } else {
      avatarImage.image = nil
      nameLabel.isHidden = false
      avatarImage.backgroundColor = UIColor
        .colorWithString(string: model.message?.from)
    }

    if model.fullNameHeight > 0 {
      fullNameLabel.text = model.fullName
      fullNameLabel.isHidden = false
      bubbleTopAnchorLeft?.constant = 0
    } else {
      fullNameLabel.text = nil
      fullNameLabel.isHidden = true
      bubbleTopAnchorLeft?.constant = 4
    }
    fullNameH?.constant = CGFloat(model.fullNameHeight)

    if isSend {
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
    }

    if isSend, model.message?.deliveryState == .deliveried {
      if model.message?.session?.sessionType == .P2P {
        let receiptEnable = model.message?.setting?.teamReceiptEnabled ?? false
        if receiptEnable,
           IMKitClient.instance.getSettingRepo().getShowReadStatus(),
           NEKitChatConfig.shared.ui.messageProperties.showP2pMessageStatus == true {
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
           IMKitClient.instance.getSettingRepo().getShowReadStatus(),
           NEKitChatConfig.shared.ui.messageProperties.showTeamMessageStatus == true {
          readView.isHidden = false
          let readCount = model.message?.teamReceiptInfo?.readCount ?? 0
          let unreadCount = model.message?.teamReceiptInfo?.unreadCount ?? 0
          let total = Float(readCount + unreadCount)
          if (readCount + unreadCount) >= NEKitChatConfig.shared.maxReadingNum {
            readView.isHidden = true
            return
          }
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

  /// 根据消息发送方向决定元素的显隐
  /// @param showRight    是否右侧显示（是否是发送的消息）
  open func showLeftOrRight(showRight: Bool) {
    avatarImageLeft.isHidden = showRight
    nameLabelLeft.isHidden = showRight
    bubbleImageLeft.isHidden = showRight
    pinImageLeft.isHidden = showRight
    pinLabelLeft.isHidden = showRight
    fullNameLabel.isHidden = showRight

    avatarImageRight.isHidden = !showRight
    nameLabelRight.isHidden = !showRight
    bubbleImageRight.isHidden = !showRight
    pinImageRight.isHidden = !showRight
    pinLabelRight.isHidden = !showRight
    activityView.isHidden = !showRight
    readView.isHidden = !showRight
  }

  /// 更新标记状态
  open func updatePinStatus(_ model: MessageContentModel) {
    guard let isSend = model.message?.isOutgoingMsg else {
      return
    }
    let pinLabel = isSend ? pinLabelRight : pinLabelLeft
    let pinImage = isSend ? pinImageRight : pinImageLeft
    let pinLabelH = isSend ? pinLabelHRight : pinLabelHLeft
    let pinLabelW = isSend ? pinLabelWRight : pinLabelWLeft

    pinLabel.isHidden = !model.isPined
    pinImage.isHidden = !model.isPined
    contentView.backgroundColor = model.isPined ? NEKitChatConfig.shared.ui
      .messageProperties.signalBgColor : .clear
    if model.isPined {
      let pinText = model.message?.session?.sessionType == .P2P ? chatLocalizable("pin_text_P2P") : chatLocalizable("pin_text_team")
      if model.pinAccount == nil {
        pinLabel.text = chatLocalizable("You") + " " + pinText
      } else if let account = model.pinAccount, account == NIMSDK.shared().loginManager.currentAccount() {
        pinLabel.text = chatLocalizable("You") + " " + pinText
      } else if let text = model.pinShowName {
        pinLabel.text = text + pinText
      }

      pinImage.image = UIImage.ne_imageNamed(name: "msg_pin")
      let size = String.getTextRectSize(
        pinLabel.text ?? pinText,
        font: UIFont.systemFont(ofSize: 12.0),
        size: CGSize(width: pinLabelMaxWidth, height: CGFloat.greatestFiniteMagnitude)
      )
      pinLabelH?.constant = CGFloat(chat_pin_height)
      pinLabelW?.constant = min(size.width + 1, pinLabelMaxWidth)
    } else {
      pinImage.image = nil
      pinLabelH?.constant = 0
      pinLabelW?.constant = 0
    }
  }

  /// 设置头像大小（正方形）
  func setAvatarImgSize(size: CGFloat) {
    NSLayoutConstraint.deactivate(avatarImageLeft.constraints)
    NSLayoutConstraint.activate([
      avatarImageLeft.widthAnchor.constraint(equalToConstant: size),
      avatarImageLeft.heightAnchor.constraint(equalToConstant: size),
    ])
    NSLayoutConstraint.deactivate(avatarImageRight.constraints)
    NSLayoutConstraint.activate([
      avatarImageRight.widthAnchor.constraint(equalToConstant: size),
      avatarImageRight.heightAnchor.constraint(equalToConstant: size),
    ])
  }

  func sizeWidthFromString(_ text: NSAttributedString, _ font: UIFont) -> Double {
    // 根据内容计算size
    let maxSize = CGSize(width: chat_content_maxW, height: CGFloat.greatestFiniteMagnitude)
    let labelSize = text.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    return ceil(labelSize.width) + chat_content_margin * 2
  }

  func sizeHeightFromString(_ text: NSAttributedString, _ font: UIFont) -> Double {
    // 根据内容计算size
    let maxSize = CGSize(width: chat_content_maxW, height: CGFloat.greatestFiniteMagnitude)
    let labelSize = text.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)

    return ceil(labelSize.height) + chat_content_margin * 2
  }
}
