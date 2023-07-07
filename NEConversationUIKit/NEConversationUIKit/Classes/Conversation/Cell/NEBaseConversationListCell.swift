
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objcMembers
open class NEBaseConversationListCell: UITableViewCell {
//  private var viewModel = ConversationViewModel()
  public var topStickInfos = [NIMSession: NIMStickTopSessionInfo]()
  private let repo = ConversationRepo()
  private var timeWidth: NSLayoutConstraint?

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupSubviews()
    initSubviewsLayout()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open func setupSubviews() {
    selectionStyle = .none
    contentView.addSubview(headImge)
    contentView.addSubview(redAngleView)
    contentView.addSubview(title)
    contentView.addSubview(subTitle)
    contentView.addSubview(timeLabel)
    contentView.addSubview(notifyMsg)

    NSLayoutConstraint.activate([
      redAngleView.centerXAnchor.constraint(equalTo: headImge.rightAnchor, constant: -8),
      redAngleView.centerYAnchor.constraint(equalTo: headImge.topAnchor, constant: 8),
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
      subTitle.leftAnchor.constraint(equalTo: headImge.rightAnchor, constant: 12),
      subTitle.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -50),
      subTitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
    ])
  }

  func initSubviewsLayout() {}

  open func configData(sessionModel: ConversationListModel?) {
    guard let conversationModel = sessionModel else { return }

    if conversationModel.recentSession?.session?.sessionType == .P2P {
      // p2p head image
      if let imageName = conversationModel.userInfo?.userInfo?.avatarUrl {
        headImge.setTitle("")
        headImge.sd_setImage(with: URL(string: imageName), completed: nil)
        headImge.backgroundColor = .clear
      } else {
        headImge.setTitle(conversationModel.userInfo?.shortName(showAlias: false, count: 2) ?? "")
        headImge.sd_setImage(with: nil, completed: nil)
        headImge.backgroundColor = UIColor
          .colorWithString(string: conversationModel.userInfo?.userId)
      }

      // p2p nickName
      title.text = conversationModel.userInfo?.showName()

      // notifyForNewMsg
//      notifyMsg.isHidden = viewModel
//        .notifyForNewMsg(userId: conversationModel.userInfo?.userId)
      notifyMsg.isHidden = repo.isNeedNotify(userId: conversationModel.userInfo?.userId)

    } else if conversationModel.recentSession?.session?.sessionType == .team {
      // team head image
      if let imageName = conversationModel.teamInfo?.avatarUrl {
        headImge.setTitle("")
        headImge.sd_setImage(with: URL(string: imageName), completed: nil)
        headImge.backgroundColor = .clear
      } else {
        headImge.setTitle(conversationModel.teamInfo?.getShowName() ?? "")
        headImge.sd_setImage(with: nil, completed: nil)
        headImge.backgroundColor = UIColor
          .colorWithString(string: conversationModel.teamInfo?.teamId)
      }
      title.text = conversationModel.teamInfo?.getShowName()

      // notifyForNewMsg
//      let teamNotifyState = viewModel
//        .notifyStateForNewMsg(teamId: conversationModel.teamInfo?.teamId)
      let teamNotifyState = repo.isNeedNotifyForTeam(teamId: conversationModel.teamInfo?.teamId)
      notifyMsg.isHidden = teamNotifyState == .none ? false : true
    }

    // last message
    if let lastMessage = conversationModel.recentSession?.lastMessage {
      let text = contentForRecentSession(message: lastMessage)
      let mutaAttri = NSMutableAttributedString(string: text)
      if let sessionId = sessionModel?.recentSession?.session?.sessionId {
        let isAtMessage = NEAtMessageManager.instance.isAtCurrentUser(sessionId: sessionId)
        if isAtMessage == true {
          let atStr = localizable("you_were_mentioned")
          mutaAttri.insert(NSAttributedString(string: atStr), at: 0)
          mutaAttri.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ne_redText, range: NSMakeRange(0, atStr.count))
          mutaAttri.addAttribute(NSAttributedString.Key.font, value: NEKitConversationConfig.shared.ui.subTitleFont, range: NSMakeRange(0, mutaAttri.length))
        }
      }
      subTitle.attributedText = mutaAttri // contentForRecentSession(message: lastMessage)
    }

    // unRead message count
    if let unReadCount = conversationModel.recentSession?.unreadCount {
      if unReadCount <= 0 {
        redAngleView.isHidden = true
      } else {
        redAngleView.isHidden = notifyMsg.isHidden ? false : true
        if unReadCount <= 99 {
          redAngleView.text = "\(unReadCount)"
        } else {
          redAngleView.text = "99+"
        }
      }
    }

    // time
    if let rencentSession = conversationModel.recentSession {
      timeLabel
        .text =
        dealTime(time: timestampDescriptionForRecentSession(recentSession: rencentSession))
      if let text = timeLabel.text {
        let maxSize = CGSize(width: UIScreen.main.bounds.width, height: 0)
        let attibutes = [NSAttributedString.Key.font: timeLabel.font]
        let labelSize = NSString(string: text).boundingRect(with: maxSize, attributes: attibutes, context: nil)
        timeWidth?.constant = labelSize.width + 1 // ceil()
      }
    }
  }

  func timestampDescriptionForRecentSession(recentSession: NIMRecentSession) -> TimeInterval {
    if let lastMessage = recentSession.lastMessage {
      return lastMessage.timestamp
    }
    // 服务端时间戳以毫秒为单位,需要转化
    return recentSession.updateTime / 1000
  }

  func dealTime(time: TimeInterval) -> String {
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

  open func contentForRecentSession(message: NIMMessage) -> String {
    let text = NEMessageUtil.messageContent(message: message)
    return text
  }

  // MARK: lazy Method

  public lazy var headImge: NEUserHeaderView = {
    let headView = NEUserHeaderView(frame: .zero)
    headView.titleLabel.textColor = .white
    headView.titleLabel.font = NEConstant.defaultTextFont(14)
    headView.translatesAutoresizingMaskIntoConstraints = false
    headView.layer.cornerRadius = 21
    headView.clipsToBounds = true
    return headView
  }()

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

  public lazy var title: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEKitConversationConfig.shared.ui.titleColor
    label.font = NEKitConversationConfig.shared.ui.titleFont ?? UIFont.systemFont(ofSize: 16)
    label.text = "Oliver"
    return label
  }()

  public lazy var subTitle: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEKitConversationConfig.shared.ui.subTitleColor
    label.font = NEKitConversationConfig.shared.ui.subTitleFont
    return label
  }()

  public lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEKitConversationConfig.shared.ui.timeColor
    label.font = NEKitConversationConfig.shared.ui.timeFont
    label.textAlignment = .right
    return label
  }()

  public lazy var notifyMsg: UIImageView = {
    let notify = UIImageView()
    notify.translatesAutoresizingMaskIntoConstraints = false
    notify.image = UIImage.ne_imageNamed(name: "noNeed_notify")
    notify.isHidden = true
    return notify
  }()
}
