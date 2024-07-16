
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class NEBaseConversationListCell: UITableViewCell {
  public var topStickInfos = [NIMSession: NIMStickTopSessionInfo]()

  private var timeWidth: NSLayoutConstraint?

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
    if let bgColor = NEKitConversationConfig.shared.ui.conversationProperties.itemBackground {
      backgroundColor = bgColor
    }

    contentView.addSubview(headImageView)
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

  func initSubviewsLayout() {}

  /// 数据绑定UI
  /// - Parameter sessionModel: 会话数据
  open func configureData(_ sessionModel: NEConversationListModel?) {
    guard let conversationModel = sessionModel else { return }
    if conversationModel.conversation?.type == .CONVERSATION_TYPE_P2P {
      // p2p head image
      if let imageName = conversationModel.conversation?.avatar, !imageName.isEmpty {
        headImageView.setTitle("")
        headImageView.sd_setImage(with: URL(string: imageName), completed: nil)
        headImageView.backgroundColor = .clear
      } else {
        if let name = conversationModel.conversation?.shortName(count: 2) {
          headImageView.setTitle(name)
        } else if let conversationId = conversationModel.conversation?.conversationId {
          // 截断长度
          let count = 2
          let showId = conversationId
            .count > count ? String(conversationId[conversationId.index(conversationId.endIndex, offsetBy: -count)...]) : conversationId
          headImageView.setTitle(showId)
        }
        headImageView.sd_setImage(with: nil, completed: nil)
        if let cid = conversationModel.conversation?.conversationId, let uid = V2NIMConversationIdUtil.conversationTargetId(cid) {
          headImageView.backgroundColor = UIColor
            .colorWithString(string: uid)
        }
      }

      // p2p nickName
      if let name = conversationModel.conversation?.name, name.count > 0 {
        titleLabel.text = conversationModel.conversation?.name
      } else if let conversationId = conversationModel.conversation?.conversationId, let accountId = V2NIMConversationIdUtil.conversationTargetId(conversationId) {
        titleLabel.text = accountId
      }

    } else if conversationModel.conversation?.type == .CONVERSATION_TYPE_TEAM {
      // team head image
      if let imageName = conversationModel.conversation?.avatar, !imageName.isEmpty {
        headImageView.setTitle("")
        headImageView.sd_setImage(with: URL(string: imageName), completed: nil)
        headImageView.backgroundColor = .clear
      } else {
        headImageView.setTitle(conversationModel.conversation?.name ?? "")
        headImageView.sd_setImage(with: nil, completed: nil)
        if let name = conversationModel.conversation?.shortName(count: 2) {
          headImageView.setTitle(name)
        } else if let conversationId = conversationModel.conversation?.conversationId {
          // 截断长度
          let count = 2
          let showId = conversationId
            .count > count ? String(conversationId[conversationId.index(conversationId.endIndex, offsetBy: -count)...]) : conversationId
          headImageView.setTitle(showId)
        }
        if let cid = conversationModel.conversation?.conversationId, let uid = V2NIMConversationIdUtil.conversationTargetId(cid) {
          headImageView.backgroundColor = UIColor
            .colorWithString(string: uid)
        }
      }
      titleLabel.text = conversationModel.conversation?.name
      if let name = conversationModel.conversation?.name {
        titleLabel.text = name
      } else if let conversationId = conversationModel.conversation?.conversationId, let teamId = V2NIMConversationIdUtil.conversationTargetId(conversationId) {
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
          mutaAttri.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: NEKitConversationConfig.shared.ui.conversationProperties.itemContentSize > 0 ? NEKitConversationConfig.shared.ui.conversationProperties.itemContentSize : 13), range: NSMakeRange(0, mutaAttri.length))
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
        .text =
        dealTime(time: time)
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

  func dealTime(time: TimeInterval) -> String {
    if time <= 0 {
      return ""
    }

    let targetDate = Date(timeIntervalSince1970: time)
    let fmt = DateFormatter()

    if targetDate.isToday() {
      fmt.dateFormat = localizable("hm")
      return fmt.string(from: targetDate)

    } else {
      if targetDate.isThisYear() {
        fmt.dateFormat = localizable("mdhm")
        return fmt.string(from: targetDate)

      } else {
        fmt.dateFormat = localizable("ymdhm")
        return fmt.string(from: targetDate)
      }
    }
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

  // 会话列表会话名称
  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEKitConversationConfig.shared.ui.conversationProperties.itemTitleColor
    label.font = .systemFont(ofSize: NEKitConversationConfig.shared.ui.conversationProperties.itemTitleSize > 0 ? NEKitConversationConfig.shared.ui.conversationProperties.itemTitleSize : 16)
    label.text = "Oliver"
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  // 会话列表外露消息
  public lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEKitConversationConfig.shared.ui.conversationProperties.itemContentColor
    label.font = UIFont.systemFont(ofSize: NEKitConversationConfig.shared.ui.conversationProperties.itemContentSize > 0 ? NEKitConversationConfig.shared.ui.conversationProperties.itemContentSize : 13)
    label.accessibilityIdentifier = "id.message"
    return label
  }()

  // 会话列表显示时间
  public lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEKitConversationConfig.shared.ui.conversationProperties.itemDateColor
    label.font = .systemFont(ofSize: NEKitConversationConfig.shared.ui.conversationProperties.itemDateSize > 0 ? NEKitConversationConfig.shared.ui.conversationProperties.itemDateSize : 12)
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
