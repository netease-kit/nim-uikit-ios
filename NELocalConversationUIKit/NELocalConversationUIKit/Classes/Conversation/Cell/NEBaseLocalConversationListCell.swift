
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseLocalConversationListCell: UITableViewCell {
  private var timeWidth: NSLayoutConstraint?
  private var conversationType: V2NIMConversationType = .CONVERSATION_TYPE_UNKNOWN
  private var sessionId = ""

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupSubviews()
    initSubviewsLayout()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupSubviews() {
    selectionStyle = .none
    backgroundColor = .clear

    contentView.addSubview(headImageView)
    contentView.addSubview(onlineView)
    contentView.addSubview(redAngleView)
    contentView.addSubview(mutedUnreadDotView)
    contentView.addSubview(titleContentView)
    robotIconWidthConstraint = robotIconView.widthAnchor.constraint(equalToConstant: 0)
    robotIconWidthConstraint?.isActive = true
    NSLayoutConstraint.activate([
      robotIconView.heightAnchor.constraint(equalToConstant: 18),
      robotIconView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
    ])
    contentView.addSubview(subTitleLabel)
    contentView.addSubview(timeLabel)
    contentView.addSubview(notifyMsgView)

    NSLayoutConstraint.activate([
      redAngleView.centerXAnchor.constraint(equalTo: headImageView.rightAnchor, constant: -8),
      redAngleView.centerYAnchor.constraint(equalTo: headImageView.topAnchor, constant: 8),
      redAngleView.heightAnchor.constraint(equalToConstant: 18),
    ])
    NSLayoutConstraint.activate([
      mutedUnreadDotView.centerXAnchor.constraint(equalTo: redAngleView.centerXAnchor, constant: 3),
      mutedUnreadDotView.centerYAnchor.constraint(equalTo: redAngleView.centerYAnchor, constant: -3),
      mutedUnreadDotView.widthAnchor.constraint(equalToConstant: 8),
      mutedUnreadDotView.heightAnchor.constraint(equalToConstant: 8),
    ])

    NSLayoutConstraint.activate([
      onlineView.rightAnchor.constraint(equalTo: headImageView.rightAnchor),
      onlineView.bottomAnchor.constraint(equalTo: headImageView.bottomAnchor),
      onlineView.widthAnchor.constraint(equalToConstant: 12),
      onlineView.heightAnchor.constraint(equalToConstant: 12),
    ])

    timeWidth = timeLabel.widthAnchor.constraint(equalToConstant: 0)
    timeWidth?.isActive = true
    NSLayoutConstraint.activate([
      timeLabel.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -NEConstant.screenInterval
      ),
      timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 17),
    ])

    NSLayoutConstraint.activate([
      subTitleLabel.leftAnchor.constraint(equalTo: headImageView.rightAnchor, constant: 12),
      subTitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -50),
      subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
    ])
  }

  open func setOnline(_ online: Bool) {
    onlineView.isHidden = conversationType != .CONVERSATION_TYPE_P2P ||
      NEAIUserManager.shared.isAIUser(sessionId) ||
      NEAIRobotManager.shared.isRobot(sessionId)
    onlineView.backgroundColor = online ? UIColor(hexString: "#84ED85") : UIColor(hexString: "#D4D9DA")
  }

  open func initSubviewsLayout() {}

  /// 数据绑定UI
  /// - Parameter sessionModel: 会话数据
  open func configureData(_ sessionModel: NELocalConversationListModel?) {
    guard let conversationModel = sessionModel else {
      return
    }

    conversationType = conversationModel.conversation?.type ?? .CONVERSATION_TYPE_UNKNOWN

    if conversationModel.conversation?.type == .CONVERSATION_TYPE_P2P {
      guard let conversationId = conversationModel.conversation?.conversationId,
            let accountId = V2NIMConversationIdUtil.conversationTargetId(conversationId) else {
        return
      }

      sessionId = accountId

      // p2p head image
      let url = conversationModel.conversation?.avatar
      let name = NEConversationAvatarNameHelper.name(
        accountId: accountId,
        conversationName: conversationModel.conversation?.name
      )
      headImageView.configHeadData(headUrl: url, name: name, uid: accountId)

      // p2p nickName
      let displayName = conversationModel.conversation?.name.flatMap { $0.isEmpty ? nil : $0 } ?? accountId
      configureTitle(displayName, isRobot: NEAIRobotManager.shared.isRobot(sessionId))
      refreshRobotIconIfNeeded(displayName: displayName)
    } else if conversationModel.conversation?.type == .CONVERSATION_TYPE_TEAM {
      guard let conversationId = conversationModel.conversation?.conversationId,
            let teamId = V2NIMConversationIdUtil.conversationTargetId(conversationId) else {
        return
      }

      sessionId = teamId

      // team head image
      let url = conversationModel.conversation?.avatar
      let name = conversationModel.conversation?.shortName() ?? ""
      headImageView.configHeadData(headUrl: url, name: name, uid: teamId)

      let displayName = conversationModel.conversation?.name.flatMap { $0.isEmpty ? nil : $0 } ?? teamId
      configureTitle(displayName, isRobot: false)
    }

    // notifyForNewMsg
    let isMuted = conversationModel.conversation?.mute == true
    notifyMsgView.isHidden = !isMuted

    // last message
    if let lastMessage = conversationModel.conversation?.lastMessage {
      let text = contentForConversation(lastMessage: lastMessage)
      let mutaAttri = NSMutableAttributedString()
      appendBotSubSessionPrefixIfNeeded(to: mutaAttri)
      if let lastContent = conversationModel.lastMessageConent {
        mutaAttri.append(lastContent)
      } else {
        mutaAttri.append(NSAttributedString(string: text))
      }
      if let sessionId = conversationModel.conversation?.conversationId {
        let isAtMessage = NELocalAtMessageManager.instance?.isAtCurrentUser(conversationId: sessionId)
        if isAtMessage == true {
          let atStr = localizable("you_were_mentioned")
          mutaAttri.insert(NSAttributedString(string: atStr), at: 0)
          mutaAttri.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ne_redText, range: NSMakeRange(0, atStr.count))
          mutaAttri.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: LocalConversationUIConfig.shared.conversationProperties.itemContentSize > 0 ? LocalConversationUIConfig.shared.conversationProperties.itemContentSize : 13), range: NSMakeRange(0, mutaAttri.length))
        }
      }
      subTitleLabel.attributedText = mutaAttri
      refreshBotSubSessionPrefixIfNeeded()
    } else {
      subTitleLabel.attributedText = nil
    }

    // unRead message count
    let unreadCount = conversationModel.unreadCount
    redAngleView.isHidden = isMuted || unreadCount <= 0
    mutedUnreadDotView.isHidden = !isMuted || unreadCount <= 0
    if unreadCount <= 0 {
      redAngleView.text = nil
    } else if unreadCount <= 99 {
      redAngleView.text = "\(unreadCount)"
    } else {
      redAngleView.text = "99+"
    }

    // time
    var useTime: TimeInterval?

    if let createTime = conversationModel.conversation?.lastMessage?.messageRefer.createTime {
      useTime = createTime

    } else if let updateTime = conversationModel.conversation?.updateTime {
      useTime = updateTime
    }
    if let time = useTime {
      timeLabel
        .text = String.stringFromTimeInterval(time: time)
      if let text = timeLabel.text {
        let maxSize = CGSize(width: UIScreen.main.bounds.width, height: 0)
        let attibutes = [NSAttributedString.Key.font: timeLabel.font]
        let labelSize = NSString(string: text).boundingRect(with: maxSize, attributes: attibutes as [NSAttributedString.Key: Any], context: nil)
        timeWidth?.constant = labelSize.width + 1 // ceil()
      }
    } else {
      timeLabel.text = ""
    }
  }

  func timestampDescriptionForRecentSession(recentSession: NIMRecentSession) -> TimeInterval {
    if let lastMessage = recentSession.lastMessage {
      return lastMessage.timestamp
    }

    return 0
  }

  open func contentForConversation(lastMessage: V2NIMLastMessage) -> String {
    let text = NEMessageUtil.messageContent(lastMessage.messageType, lastMessage.text, lastMessage.attachment)
    return text
  }

  private func configureTitle(_ title: String, isRobot: Bool) {
    titleLabel.attributedText = nil
    titleLabel.text = title
    robotIconView.isHidden = !isRobot
    robotIconWidthConstraint?.constant = isRobot ? 22 : 0
  }

  private func refreshRobotIconIfNeeded(displayName: String) {
    guard conversationType == .CONVERSATION_TYPE_P2P,
          !sessionId.isEmpty else {
      return
    }
    let expectedSessionId = sessionId
    NEAIRobotManager.shared.checkIfRobot(expectedSessionId) { [weak self] isRobot in
      DispatchQueue.main.async {
        // The cell may be rebound after the robot lookup completes but before
        // this deferred UI update runs. Recheck the conversation identity at
        // the point where the title is written to prevent stale names from
        // overwriting a reused cell.
        guard let self,
              self.conversationType == .CONVERSATION_TYPE_P2P,
              self.sessionId == expectedSessionId else {
          return
        }
        self.configureTitle(displayName, isRobot: isRobot)
      }
    }
  }

  open func appendBotSubSessionPrefixIfNeeded(to content: NSMutableAttributedString) {
    if conversationType == .CONVERSATION_TYPE_P2P,
       NEAIRobotManager.shared.isRobot(sessionId) {
      content.append(botSubSessionPrefixAttributedString())
    }
  }

  open func refreshBotSubSessionPrefixIfNeeded() {
    guard conversationType == .CONVERSATION_TYPE_P2P,
          !sessionId.isEmpty else {
      return
    }
    let expectedSessionId = sessionId
    NEAIRobotManager.shared.checkIfRobot(expectedSessionId) { [weak self] isRobot in
      guard let self,
            self.conversationType == .CONVERSATION_TYPE_P2P,
            self.sessionId == expectedSessionId else {
        return
      }
      if isRobot {
        self.insertBotSubSessionPrefixIfNeeded()
      } else {
        self.removeBotSubSessionPrefixIfNeeded()
      }
    }
  }

  private func removeBotSubSessionPrefixIfNeeded() {
    let prefix = localizable("bot_sub_session_prefix")
    guard let current = subTitleLabel.attributedText else {
      return
    }
    let range = (current.string as NSString).range(of: prefix)
    guard range.location != NSNotFound else {
      return
    }
    let content = NSMutableAttributedString(attributedString: current)
    content.deleteCharacters(in: range)
    subTitleLabel.attributedText = content
  }

  open func insertBotSubSessionPrefixIfNeeded() {
    let prefix = localizable("bot_sub_session_prefix")
    guard let current = subTitleLabel.attributedText,
          !current.string.contains(prefix) else {
      return
    }
    let content = NSMutableAttributedString(attributedString: current)
    let atPrefix = localizable("you_were_mentioned")
    let insertIndex = content.string.hasPrefix(atPrefix) ? atPrefix.count : 0
    content.insert(botSubSessionPrefixAttributedString(), at: insertIndex)
    subTitleLabel.attributedText = content
  }

  private func botSubSessionPrefixAttributedString() -> NSAttributedString {
    NSAttributedString(
      string: localizable("bot_sub_session_prefix"),
      attributes: [
        .font: UIFont.systemFont(ofSize: LocalConversationUIConfig.shared.conversationProperties.itemContentSize > 0 ? LocalConversationUIConfig.shared.conversationProperties.itemContentSize : 13),
        .foregroundColor: LocalConversationUIConfig.shared.conversationProperties.itemContentColor,
      ]
    )
  }

  // MARK: lazy Method

  public lazy var headImageView: NEUserHeaderView = {
    let headView = NEUserHeaderView(frame: .zero)
    headView.titleLabel.textColor = .white
    headView.titleLabel.font = NEConstant.defaultTextFont(14)
    headView.translatesAutoresizingMaskIntoConstraints = false
    headView.layer.cornerRadius = 21
    headView.clipsToBounds = true
    return headView
  }()

  // 单条会话未读数
  public lazy var redAngleView: RedAngleLabel = {
    let label = RedAngleLabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(12)
    label.textColor = .white
    label.text = "99+"
    label.backgroundColor = NEConstant.hexRGB(0xF24957)
    label.textInsets = UIEdgeInsets(top: 3, left: 7, bottom: 3, right: 7)
    label.layer.cornerRadius = 9
    label.clipsToBounds = true
    label.isHidden = true
    return label
  }()

  private lazy var mutedUnreadDotView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = NEConstant.hexRGB(0xF24957)
    view.layer.cornerRadius = 4
    view.isHidden = true
    view.accessibilityIdentifier = "id.mutedUnreadDot"
    return view
  }()

  /// 在线状态
  public lazy var onlineView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer.cornerRadius = 6
    view.backgroundColor = UIColor(hexString: "#D4D9DA")
    view.isHidden = true
    return view
  }()

  // 会话列表会话名称
  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = LocalConversationUIConfig.shared.conversationProperties.itemTitleColor
    label.font = .systemFont(ofSize: LocalConversationUIConfig.shared.conversationProperties.itemTitleSize > 0 ? LocalConversationUIConfig.shared.conversationProperties.itemTitleSize : 16)
    label.text = "Oliver"
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingTail
    label.setContentHuggingPriority(.required, for: .horizontal)
    label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  public lazy var titleContentView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [titleLabel, robotIconView])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.spacing = 2
    stackView.distribution = .fill
    stackView.setContentHuggingPriority(.required, for: .horizontal)
    stackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    return stackView
  }()

  public lazy var robotIconView: UIImageView = {
    let imageView = UIImageView(image: UIImage.ne_imageNamed(name: "robot_icon"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    imageView.isHidden = true
    return imageView
  }()

  private var robotIconWidthConstraint: NSLayoutConstraint?

  // 会话列表外露消息
  public lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = LocalConversationUIConfig.shared.conversationProperties.itemContentColor
    label.font = UIFont.systemFont(ofSize: LocalConversationUIConfig.shared.conversationProperties.itemContentSize > 0 ? LocalConversationUIConfig.shared.conversationProperties.itemContentSize : 13)
    label.accessibilityIdentifier = "id.message"
    return label
  }()

  // 会话列表显示时间
  public lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = LocalConversationUIConfig.shared.conversationProperties.itemDateColor
    label.font = .systemFont(ofSize: LocalConversationUIConfig.shared.conversationProperties.itemDateSize > 0 ? LocalConversationUIConfig.shared.conversationProperties.itemDateSize : 12)
    label.textAlignment = .right
    label.accessibilityIdentifier = "id.time"
    return label
  }()

  // 免打扰icon
  public lazy var notifyMsgView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = UIImage.ne_imageNamed(name: "noNeed_notify")
    imageView.isHidden = true
    imageView.accessibilityIdentifier = "id.mute"
    return imageView
  }()
}
