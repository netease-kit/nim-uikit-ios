
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class NEBaseConversationListCell: UITableViewCell {
  public var topStickInfos = [NIMSession: NIMStickTopSessionInfo]()

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
    contentView.addSubview(titleLabel)
    contentView.addSubview(subTitleLabel)
    contentView.addSubview(timeLabel)
    contentView.addSubview(notifyMsgView)

    NSLayoutConstraint.activate([
      redAngleView.centerXAnchor.constraint(equalTo: headImageView.rightAnchor, constant: -8),
      redAngleView.centerYAnchor.constraint(equalTo: headImageView.topAnchor, constant: 8),
      redAngleView.heightAnchor.constraint(equalToConstant: 18),
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
    onlineView.isHidden = conversationType != .CONVERSATION_TYPE_P2P || NEAIUserManager.shared.isAIUser(sessionId)
    onlineView.backgroundColor = online ? UIColor(hexString: "#84ED85") : UIColor(hexString: "#D4D9DA")
  }

  open func initSubviewsLayout() {}

  /// 数据绑定UI
  /// - Parameter sessionModel: 会话数据
  open func configureData(_ sessionModel: NEConversationListModel?) {
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
      let name = conversationModel.conversation?.shortName() ?? ""
      headImageView.configHeadData(headUrl: url, name: name, uid: accountId)

      // p2p nickName
      if let name = conversationModel.conversation?.name, !name.isEmpty {
        titleLabel.text = name
      } else {
        titleLabel.text = accountId
      }
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

      // team nickName
      if let name = conversationModel.conversation?.name, !name.isEmpty {
        titleLabel.text = name
      } else {
        titleLabel.text = teamId
      }
    }

    // notifyForNewMsg
    if let mute = conversationModel.conversation?.mute {
      notifyMsgView.isHidden = !mute
    }

    // last message
    if let lastMessage = conversationModel.conversation?.lastMessage {
      let text = contentForConversation(lastMessage: lastMessage)
      let mutaAttri = NSMutableAttributedString()
      if let lastContent = conversationModel.lastMessageConent {
        mutaAttri.append(lastContent)
      } else {
        mutaAttri.append(NSAttributedString(string: text))
      }
      if let sessionId = conversationModel.conversation?.conversationId {
        let isAtMessage = NEAtMessageManager.instance?.isAtCurrentUser(conversationId: sessionId)
        if isAtMessage == true {
          let atStr = localizable("you_were_mentioned")
          mutaAttri.insert(NSAttributedString(string: atStr), at: 0)
          mutaAttri.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ne_redText, range: NSMakeRange(0, atStr.count))
          mutaAttri.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: ConversationUIConfig.shared.conversationProperties.itemContentSize > 0 ? ConversationUIConfig.shared.conversationProperties.itemContentSize : 13), range: NSMakeRange(0, mutaAttri.length))
        }
      }
      subTitleLabel.attributedText = mutaAttri
    } else {
      subTitleLabel.attributedText = nil
    }

    // unRead message count
    if let unReadCount = conversationModel.conversation?.unreadCount {
      if unReadCount <= 0 {
        redAngleView.isHidden = true
      } else {
        redAngleView.isHidden = notifyMsgView.isHidden ? false : true
        if unReadCount <= 99 {
          redAngleView.text = "\(unReadCount)"
        } else {
          redAngleView.text = "99+"
        }
      }
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

  open func timestampDescriptionForRecentSession(recentSession: NIMRecentSession) -> TimeInterval {
    if let lastMessage = recentSession.lastMessage {
      return lastMessage.timestamp
    }

    return 0
  }

  open func contentForConversation(lastMessage: V2NIMLastMessage) -> String {
    let text = NEMessageUtil.messageContent(lastMessage.messageType, lastMessage.text, lastMessage.attachment)
    return text
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

  /// 单条会话未读数
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
    label.textColor = ConversationUIConfig.shared.conversationProperties.itemTitleColor
    label.font = .systemFont(ofSize: ConversationUIConfig.shared.conversationProperties.itemTitleSize > 0 ? ConversationUIConfig.shared.conversationProperties.itemTitleSize : 16)
    label.text = "Oliver"
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  // 会话列表外露消息
  public lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = ConversationUIConfig.shared.conversationProperties.itemContentColor
    label.font = UIFont.systemFont(ofSize: ConversationUIConfig.shared.conversationProperties.itemContentSize > 0 ? ConversationUIConfig.shared.conversationProperties.itemContentSize : 13)
    label.accessibilityIdentifier = "id.message"
    return label
  }()

  // 会话列表显示时间
  public lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = ConversationUIConfig.shared.conversationProperties.itemDateColor
    label.font = .systemFont(ofSize: ConversationUIConfig.shared.conversationProperties.itemDateSize > 0 ? ConversationUIConfig.shared.conversationProperties.itemDateSize : 12)
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
