
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
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
  func didTapMessageView(_ cell: UITableViewCell, _ model: MessageContentModel?, _ replyModel: MessageModel?)

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

  // 划词选中失去焦点
  @objc optional func didTextViewLoseFocus(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 消息即将展示
  @objc optional func messageWillShow(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 停止流式消息
  @objc optional func stopAIStreamMessage(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 重新生成流式消息
  @objc optional func regenAIStreamMessage(_ cell: UITableViewCell, _ model: MessageContentModel?)

  // 点击自动检测的链接（url、mobile、email）
  @objc optional func didTapDetectedLink(_ cell: UITableViewCell, _ model: MessageContentModel?, _ url: URL)
}

@objc
public protocol ChatAudioCellProtocol: NSObjectProtocol {
  var isPlaying: Bool { get set }
  var messageId: String? { get set }
  func startAnimation(byRight: Bool)
  func stopAnimation(byRight: Bool)
}

@objcMembers
open class NEBaseChatMessageCell: NEChatBaseCell {
  private let pinLabelMaxWidth: CGFloat = 280 // pin 文案最大宽度
  public weak var delegate: ChatBaseCellDelegate?
  public var contentModel: MessageContentModel? // 消息模型

  /// Left
  public var userHeaderViewLeft = NEUserHeaderView(frame: .zero) // 左侧头像
  public var avatarImageLeftAnchor: NSLayoutConstraint? // 左侧头像左侧布局依赖
  public var bubbleImageLeft = UIImageView() // 左侧气泡
  public var bubbleTopAnchorLeft: NSLayoutConstraint? // 左侧气泡顶部布局约束
  public var bubbleWLeft: NSLayoutConstraint? // 左侧气泡宽度布局约束
  public var bubbleHLeft: NSLayoutConstraint? // 左侧气泡高度布局约束
  public var pinImageLeft = UIImageView() // 左侧标记图片
  public var pinLabelLeft = UILabel() // 左侧标记文案
  private var pinLabelHLeft: NSLayoutConstraint? // 左侧标记文案宽度布局约束
  private var pinLabelWLeft: NSLayoutConstraint? // 左侧标记文案高度布局约束
  public var fullNameLabel = UILabel() // 群昵称（只在群聊中有效）
  public var fullNameH: NSLayoutConstraint? // 群昵称高度布局约束

  /// Right
  public var userHeaderViewRight = NEUserHeaderView(frame: .zero) // 右侧头像
  public var bubbleImageRight = UIImageView() // 右侧气泡
  public var bubbleWRight: NSLayoutConstraint? // 右侧气泡宽度布局约束
  public var bubbleHRight: NSLayoutConstraint? // 右侧气泡高度布局约束
  public var pinImageRight = UIImageView() // 右侧标记图片
  public var pinLabelRight = UILabel() // 右侧标记文案
  private var pinLabelHRight: NSLayoutConstraint? // 右侧标记文案宽度布局约束
  private var pinLabelWRight: NSLayoutConstraint? // 右侧标记文案高度布局约束

  // 已读未读视图
  public var readView = CirleProgressView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
  public var activityView = ChatActivityIndicatorView() // 消息状态视图
  public var activityViewCenterYAnchor: NSLayoutConstraint? // 消息状态视图 Y 布局约束
  public var selectedButton = UIButton(type: .custom) // 多选按钮
  public var selectedButtonCenterYAnchor: NSLayoutConstraint? // 多选按钮中心 Y 布局约束
  public var timeLabel = UILabel() // 消息时间
  public var timeLabelHeightAnchor: NSLayoutConstraint? // 消息时间高度约束

  // 已读未读点击手势
  private var tapGesture: UITapGestureRecognizer?

  public var messageTextFont = UIFont.systemFont(ofSize: 16)
  public let messageMaxSize = CGSize(width: chat_content_maxW, height: CGFloat.greatestFiniteMagnitude)

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    initProperty()
    baseCommonUI()
    addGesture()
    initSubviewsLayout()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  deinit {
    gestureRecognizers?.forEach { gestrue in
      removeGestureRecognizer(gestrue)
    }
  }

  open func setBubbleImage() {
    var image = ChatUIConfig.shared.messageProperties.receiveMessageBgImage ?? UIImage.ne_imageNamed(name: "chat_message_receive")
    bubbleImageLeft.backgroundColor = ChatUIConfig.shared.messageProperties.receiveMessageBgColor

    if let backgroundImageCapInsets = ChatUIConfig.shared.messageProperties.backgroundImageCapInsets {
      bubbleImageLeft.image = image?.resizableImage(withCapInsets: backgroundImageCapInsets)
    } else {
      bubbleImageLeft.image = image
      bubbleImageLeft.contentMode = .scaleAspectFill
    }

    image = ChatUIConfig.shared.messageProperties.selfMessageBgImage ?? UIImage.ne_imageNamed(name: "chat_message_send")
    bubbleImageRight.backgroundColor = ChatUIConfig.shared.messageProperties.selfMessageBgColor

    if let backgroundImageCapInsets = ChatUIConfig.shared.messageProperties.backgroundImageCapInsets {
      bubbleImageRight.image = image?.resizableImage(withCapInsets: backgroundImageCapInsets)
    } else {
      bubbleImageRight.image = image
      bubbleImageRight.contentMode = .scaleAspectFill
    }
  }

  open func initProperty() {
    timeLabel.font = .systemFont(ofSize: ChatUIConfig.shared.messageProperties.timeTextSize)
    timeLabel.textColor = ChatUIConfig.shared.messageProperties.timeTextColor
    timeLabel.textAlignment = .center
    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    timeLabel.accessibilityIdentifier = "id.messageTipText"
    timeLabel.backgroundColor = .clear

    // avatar
    userHeaderViewLeft.translatesAutoresizingMaskIntoConstraints = false
    userHeaderViewLeft.clipsToBounds = true
    userHeaderViewLeft.isUserInteractionEnabled = true
    userHeaderViewLeft.titleLabel.font = UIFont.systemFont(ofSize: ChatUIConfig.shared.messageProperties.userNickTextSize)
    userHeaderViewLeft.titleLabel.textColor = ChatUIConfig.shared.messageProperties.userNickColor

    userHeaderViewRight.translatesAutoresizingMaskIntoConstraints = false
    userHeaderViewRight.clipsToBounds = true
    userHeaderViewRight.isUserInteractionEnabled = true
    userHeaderViewRight.titleLabel.font = UIFont.systemFont(ofSize: ChatUIConfig.shared.messageProperties.userNickTextSize)
    userHeaderViewRight.titleLabel.textColor = ChatUIConfig.shared.messageProperties.userNickColor

    // fullName
    fullNameLabel.translatesAutoresizingMaskIntoConstraints = false
    fullNameLabel.font = UIFont.systemFont(ofSize: 12)
    fullNameLabel.textColor = UIColor.ne_lightText
    fullNameLabel.accessibilityIdentifier = "id.fullNameLabel"

    // bubbleImage
    setBubbleImage()
    bubbleImageLeft.translatesAutoresizingMaskIntoConstraints = false
    bubbleImageLeft.isUserInteractionEnabled = true

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

    activityView.translatesAutoresizingMaskIntoConstraints = false
    activityView.failButton.addTarget(self, action: #selector(resend), for: .touchUpInside)
    activityView.accessibilityIdentifier = "id.status"

    selectedButton.translatesAutoresizingMaskIntoConstraints = false
    selectedButton.setImage(coreLoader.loadImage("unselect"), for: .normal)
    selectedButton.setImage(coreLoader.loadImage("select"), for: .selected)
    selectedButton.addTarget(self, action: #selector(selectButtonClicked), for: .touchUpInside)
  }

  open func baseCommonUI() {
    selectionStyle = .none
    backgroundColor = .clear

    // time
    contentView.addSubview(timeLabel)
    timeLabelHeightAnchor = timeLabel.heightAnchor.constraint(equalToConstant: 22)
    timeLabelHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
      timeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
      timeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -0),
    ])

    baseCommonUILeft()
    baseCommonUIRight()
  }

  open func baseCommonUILeft() {
    contentView.addSubview(userHeaderViewLeft)
    avatarImageLeftAnchor = userHeaderViewLeft.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16)
    avatarImageLeftAnchor?.isActive = true
    NSLayoutConstraint.activate([
      userHeaderViewLeft.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: chat_content_margin),
      userHeaderViewLeft.widthAnchor.constraint(equalToConstant: 32),
      userHeaderViewLeft.heightAnchor.constraint(equalToConstant: 32),
    ])

    contentView.addSubview(fullNameLabel)
    fullNameH = fullNameLabel.heightAnchor.constraint(equalToConstant: 20)
    fullNameH?.isActive = true
    NSLayoutConstraint.activate([
      fullNameLabel.leftAnchor.constraint(equalTo: userHeaderViewLeft.rightAnchor, constant: chat_content_margin),
      fullNameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
      fullNameLabel.topAnchor.constraint(equalTo: userHeaderViewLeft.topAnchor),
    ])

    //  bubbleImageLeft
    contentView.addSubview(bubbleImageLeft)
    bubbleTopAnchorLeft = bubbleImageLeft.topAnchor.constraint(equalTo: fullNameLabel.bottomAnchor, constant: 0)
    bubbleTopAnchorLeft?.isActive = true
    bubbleWLeft = bubbleImageLeft.widthAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    bubbleWLeft?.isActive = true
    bubbleHLeft = bubbleImageLeft.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    bubbleHLeft?.isActive = true
    bubbleImageLeft.leftAnchor.constraint(equalTo: userHeaderViewLeft.rightAnchor, constant: chat_content_margin).isActive = true

    contentView.addSubview(pinLabelLeft)
    pinLabelHLeft = pinLabelLeft.heightAnchor.constraint(equalToConstant: 16)
    pinLabelHLeft?.isActive = true
    pinLabelWLeft = pinLabelLeft.widthAnchor.constraint(equalToConstant: pinLabelMaxWidth)
    pinLabelWLeft?.isActive = true
    NSLayoutConstraint.activate([
      pinLabelLeft.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
      pinLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: 14),
    ])

    contentView.addSubview(pinImageLeft)
    NSLayoutConstraint.activate([
      pinImageLeft.rightAnchor.constraint(equalTo: pinLabelLeft.leftAnchor, constant: -2),
      pinImageLeft.widthAnchor.constraint(equalToConstant: 10),
      pinImageLeft.centerYAnchor.constraint(equalTo: pinLabelLeft.centerYAnchor),
    ])
  }

  open func baseCommonUIRight() {
    contentView.addSubview(userHeaderViewRight)
    NSLayoutConstraint.activate([
      userHeaderViewRight.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
      userHeaderViewRight.widthAnchor.constraint(equalToConstant: 32),
      userHeaderViewRight.heightAnchor.constraint(equalToConstant: 32),
      userHeaderViewRight.topAnchor.constraint(equalTo: userHeaderViewLeft.topAnchor, constant: 0),
    ])

    contentView.addSubview(bubbleImageRight)
    bubbleWRight = bubbleImageRight.widthAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    bubbleWRight?.isActive = true
    bubbleHRight = bubbleImageRight.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    bubbleHRight?.isActive = true
    NSLayoutConstraint.activate([
      bubbleImageRight.topAnchor.constraint(equalTo: userHeaderViewRight.topAnchor, constant: 0),
      bubbleImageRight.rightAnchor.constraint(equalTo: userHeaderViewRight.leftAnchor, constant: -chat_content_margin),
    ])

//        activityView
    contentView.addSubview(activityView)
    activityViewCenterYAnchor = activityView.centerYAnchor.constraint(equalTo: bubbleImageRight.centerYAnchor, constant: 0)
    activityViewCenterYAnchor?.isActive = true
    NSLayoutConstraint.activate([
      activityView.rightAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: -chat_content_margin),
      activityView.widthAnchor.constraint(equalToConstant: 22),
      activityView.heightAnchor.constraint(equalToConstant: 22),
    ])

//        readView
    contentView.addSubview(readView)
    NSLayoutConstraint.activate([
      readView.rightAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: -chat_content_margin),
      readView.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: 0),
      readView.widthAnchor.constraint(equalToConstant: 16),
      readView.heightAnchor.constraint(equalToConstant: 16),
    ])

//        selectedButton
    contentView.addSubview(selectedButton)
    NSLayoutConstraint.activate([
      selectedButton.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      selectedButton.widthAnchor.constraint(equalToConstant: 18),
      selectedButton.heightAnchor.constraint(equalToConstant: 18),
    ])

    contentView.addSubview(pinLabelRight)
    pinLabelHRight = pinLabelRight.heightAnchor.constraint(equalToConstant: 16)
    pinLabelHRight?.isActive = true
    pinLabelWRight = pinLabelRight.widthAnchor.constraint(equalToConstant: 210)
    pinLabelWRight?.isActive = true
    NSLayoutConstraint.activate([
      pinLabelRight.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
      pinLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: 0),
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
    avatarTapRight.cancelsTouchesInView = true
    userHeaderViewRight.addGestureRecognizer(avatarTapRight)
    let avatarTapLeft = UITapGestureRecognizer(target: self, action: #selector(tapAvatar))
    avatarTapLeft.cancelsTouchesInView = true
    userHeaderViewLeft.addGestureRecognizer(avatarTapLeft)

    let avatarLongGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressAvatar))
    avatarLongGesture.cancelsTouchesInView = false
    userHeaderViewLeft.addGestureRecognizer(avatarLongGesture)

    let messageTapRight = UITapGestureRecognizer(target: self, action: #selector(tapMessage))
    messageTapRight.cancelsTouchesInView = true
    bubbleImageRight.addGestureRecognizer(messageTapRight)
    let messageTapLeft = UITapGestureRecognizer(target: self, action: #selector(tapMessage))
    messageTapLeft.cancelsTouchesInView = true
    bubbleImageLeft.addGestureRecognizer(messageTapLeft)

    let messageLongPressRight = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    bubbleImageRight.addGestureRecognizer(messageLongPressRight)
    let messageLongPressLeft = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    bubbleImageLeft.addGestureRecognizer(messageLongPressLeft)

    let tapReadView = UITapGestureRecognizer(target: self, action: #selector(tapReadView))
    tapReadView.cancelsTouchesInView = true
    readView.addGestureRecognizer(tapReadView)
    tapGesture = tapReadView
  }

  open func initSubviewsLayout() {
    if ChatUIConfig.shared.messageProperties.avatarType == .cycle {
      userHeaderViewRight.layer.cornerRadius = 16.0
      userHeaderViewLeft.layer.cornerRadius = 16.0
    } else if ChatUIConfig.shared.messageProperties.avatarCornerRadius > 0 {
      userHeaderViewRight.layer.cornerRadius = ChatUIConfig.shared.messageProperties.avatarCornerRadius
      userHeaderViewLeft.layer.cornerRadius = ChatUIConfig.shared.messageProperties.avatarCornerRadius
    } else {
      userHeaderViewRight.layer.cornerRadius = 16.0
      userHeaderViewLeft.layer.cornerRadius = 16.0
    }
  }

//    MARK: event

  open func tapAvatar(tap: UITapGestureRecognizer) {
    delegate?.didTapAvatarView(self, contentModel)
  }

  open func tapMessage(tap: UITapGestureRecognizer) {
    delegate?.didTapMessageView(self, contentModel, contentModel?.replyedModel)
  }

  open func longPressAvatar(longPress: UITapGestureRecognizer) {
    if longPress.state == .began {
      delegate?.didLongPressAvatar(self, contentModel)
    }
  }

  open func longPress(longPress: UILongPressGestureRecognizer) {
    if longPress.state == .began {
      delegate?.didLongPressMessageView(self, contentModel)
    }
  }

  open func resend(button: UIButton) {
    print("state:default")
    delegate?.didTapResendView(self, contentModel)
  }

  open func tapReadView(tap: UITapGestureRecognizer) {
    delegate?.didTapReadView(self, contentModel)
  }

  open func selectButtonClicked() {
    selectedButton.isSelected = !selectedButton.isSelected
    if let model = contentModel {
      model.isSelected = !model.isSelected
    }
    delegate?.didTapSelectButton(self, contentModel)
  }

//    MARK: set data

  /// 设置是否允许多选
  /// - Parameters:
  ///   - model: 数据模型
  ///   - enableSelect: 是否处于多选状态
  open func setSelect(_ model: MessageContentModel, _ enableSelect: Bool = false) {
    // 多选框
    selectedButton.isHidden = model.isRevoked || !enableSelect
    selectedButton.isSelected = model.isSelected

    // 多选状态下，头像右移
    avatarImageLeftAnchor?.constant = enableSelect ? fun_chat_min_h : 16

    // 多选状态下，消息状态视图（发送失败）位置下移，避免与多选重叠
    activityViewCenterYAnchor?.constant = enableSelect ? model.contentSize.height / 2 - 12 : 0
  }

  override open func setModel(_ model: MessageContentModel) {
    setModel(model, model.message?.isSelf ?? false)
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    let bubbleW = isSend ? bubbleWRight : bubbleWLeft
    let bubbleH = isSend ? bubbleHRight : bubbleHLeft
    let userHeaderView = isSend ? userHeaderViewRight : userHeaderViewLeft
    messageTextFont = UIFont.systemFont(ofSize: isSend ? ChatUIConfig.shared.messageProperties.receiveMessageTextSize : ChatUIConfig.shared.messageProperties.selfMessageTextSize)

    contentModel = model
    contentModel?.cell = self
    tapGesture?.isEnabled = true
    showLeftOrRight(showRight: isSend)
    updatePinStatus(model, isSend)

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
    selectedButtonCenterYAnchor = selectedButton.centerYAnchor.constraint(equalTo: isSend ? bubbleImageRight.centerYAnchor : bubbleImageLeft.centerYAnchor)
    selectedButtonCenterYAnchor?.priority = .defaultHigh
    selectedButtonCenterYAnchor?.isActive = true

    // avatar
    let url = model.avatar
    let name = model.shortName ?? ""
    let accountId = ChatMessageHelper.getSenderId(model.message) ?? ""
    userHeaderView.configHeadData(headUrl: url, name: name, uid: accountId)

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
      switch model.message?.sendingState {
      case .MESSAGE_SENDING_STATE_SENDING:
        activityView.messageStatus = .sending
      case .MESSAGE_SENDING_STATE_SUCCEEDED:
        activityView.messageStatus = .successed
      case .MESSAGE_SENDING_STATE_FAILED:
        activityView.messageStatus = .failed
      default:
        activityView.messageStatus = .sending
      }
    } else {
      activityView.messageStatus = .successed
    }

    if isSend, model.message?.sendingState == .MESSAGE_SENDING_STATE_SUCCEEDED {
      if model.message?.conversationType == .CONVERSATION_TYPE_P2P {
        // 话单消息不显示已读未读
        if model.type == .rtcCallRecord {
          readView.isHidden = true
        } else {
          let receiptEnable = model.message?.messageConfig?.readReceiptEnabled ?? false
          if receiptEnable,
             !model.isRevoked,
             SettingRepo.shared.getShowReadStatus(),
             ChatUIConfig.shared.messageProperties.showP2pMessageStatus == true {
            readView.isHidden = false
            if model.readCount == 1, model.unreadCount == 0 {
              readView.progress = 1
            } else {
              readView.progress = 0
            }
          } else {
            readView.isHidden = true
          }
        }
      } else if model.message?.conversationType == .CONVERSATION_TYPE_TEAM {
        let receiptEnable = model.message?.messageConfig?.readReceiptEnabled ?? false
        if receiptEnable,
           !model.isRevoked,
           SettingRepo.shared.getShowReadStatus(),
           ChatUIConfig.shared.messageProperties.showTeamMessageStatus == true {
          readView.isHidden = false
          var total = NETeamUserManager.shared.getTeamInfo()?.memberCount ?? 0
          if model.readCount + model.unreadCount != 0 {
            total = model.readCount + model.unreadCount + 1
          }
          if total >= ChatUIConfig.shared.maxReadingNum {
            readView.isHidden = true
            return
          }
          if total - 1 > 0 {
            let progress = Float(model.readCount) / Float(total - 1)
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

    delegate?.messageWillShow?(self, model)
  }

  /// 根据消息发送方向决定元素的显隐
  /// @param showRight    是否右侧显示（是否是发送的消息）
  open func showLeftOrRight(showRight: Bool) {
    userHeaderViewLeft.isHidden = showRight
    bubbleImageLeft.isHidden = showRight
    pinImageLeft.isHidden = showRight
    pinLabelLeft.isHidden = showRight
    fullNameLabel.isHidden = showRight

    userHeaderViewRight.isHidden = !showRight
    bubbleImageRight.isHidden = !showRight
    pinImageRight.isHidden = !showRight
    pinLabelRight.isHidden = !showRight
    activityView.isHidden = !showRight
    readView.isHidden = !showRight
  }

  /// 重置文本选中状态
  open func resetSelectRange() {}

  /// 选中所有文本
  open func selectAllRange() {}

  /// 更新标记状态
  open func updatePinStatus(_ model: MessageContentModel, _ isSend: Bool) {
    let pinLabel = isSend ? pinLabelRight : pinLabelLeft
    let pinImage = isSend ? pinImageRight : pinImageLeft
    let pinLabelH = isSend ? pinLabelHRight : pinLabelHLeft
    let pinLabelW = isSend ? pinLabelWRight : pinLabelWLeft

    pinLabel.isHidden = !model.isPined
    pinImage.isHidden = !model.isPined
    contentView.backgroundColor = model.isPined ? ChatUIConfig.shared.messageProperties.signalBgColor : .clear
    if model.isPined {
      let pinText = String(format: chatLocalizable("pin_text"), chatLocalizable("You"))
      if model.pinAccount == nil {
        pinLabel.text = pinText
      } else if let account = model.pinAccount, account == IMKitClient.instance.account() {
        pinLabel.text = pinText
      } else if let text = model.pinShowName {
        pinLabel.text = String(format: chatLocalizable("pin_text"), text)
      }

      pinImage.image = UIImage.ne_imageNamed(name: "msg_pin")
      let showText = pinLabel.text ?? pinText
      let size = String.getRealSize(showText, .systemFont(ofSize: 12), CGSize(width: pinLabelMaxWidth, height: CGFloat.greatestFiniteMagnitude))
      pinLabelH?.constant = CGFloat(chat_pin_height)
      pinLabelW?.constant = min(size.width + 1, pinLabelMaxWidth)
    } else {
      pinImage.image = nil
      pinLabelH?.constant = 0
      pinLabelW?.constant = 0
    }
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
