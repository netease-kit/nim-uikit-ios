
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

open class ConversationListCell: UITableViewCell {
  private var viewModel = ConversationViewModel()
  public var topStickInfos = [NIMSession: NIMStickTopSessionInfo]()

  override open func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupSubviews()
    initSubviewsLayout()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc
  func setupSubviews() {
    selectionStyle = .none
    contentView.addSubview(headImge)
    contentView.addSubview(redAngleView)
    contentView.addSubview(title)
    contentView.addSubview(subTitle)
    contentView.addSubview(timeLabel)
    contentView.addSubview(notifyMsg)

    NSLayoutConstraint.activate([
      headImge.leftAnchor.constraint(
        equalTo: contentView.leftAnchor,
        constant: NEConstant.screenInterval
      ),
      headImge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headImge.widthAnchor.constraint(equalToConstant: 42),
      headImge.heightAnchor.constraint(equalToConstant: 42),
    ])

    NSLayoutConstraint.activate([
      redAngleView.centerXAnchor.constraint(equalTo: headImge.rightAnchor, constant: -3),
      redAngleView.centerYAnchor.constraint(equalTo: headImge.topAnchor, constant: 3),
      redAngleView.heightAnchor.constraint(equalToConstant: 18),
    ])

    NSLayoutConstraint.activate([
      timeLabel.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -NEConstant.screenInterval
      ),
      timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 17),
    ])

    NSLayoutConstraint.activate([
      title.leftAnchor.constraint(equalTo: headImge.rightAnchor, constant: 12),
      title.rightAnchor.constraint(equalTo: timeLabel.leftAnchor, constant: -5),
      title.topAnchor.constraint(equalTo: headImge.topAnchor),
    ])

    NSLayoutConstraint.activate([
      subTitle.leftAnchor.constraint(equalTo: headImge.rightAnchor, constant: 12),
      subTitle.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -50),
      subTitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
    ])

    NSLayoutConstraint.activate([
      notifyMsg.rightAnchor.constraint(equalTo: timeLabel.rightAnchor),
      notifyMsg.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 5),
      notifyMsg.widthAnchor.constraint(equalToConstant: 13),
      notifyMsg.heightAnchor.constraint(equalToConstant: 13),
    ])
  }

  func initSubviewsLayout() {
    if NEKitConversationConfig.shared.ui.avatarType == .rectangle {
      headImge.layer.cornerRadius = NEKitConversationConfig.shared.ui.avatarCornerRadius
    } else if NEKitConversationConfig.shared.ui.avatarType == .cycle {
      headImge.layer.cornerRadius = 21.0
    }
  }

  func configData(sessionModel: ConversationListModel?) {
    guard let conversationModel = sessionModel else { return }

    if conversationModel.recentSession?.session?.sessionType == .P2P {
      // p2p head image
      if let imageName = conversationModel.userInfo?.userInfo?.avatarUrl {
        headImge.setTitle("")
        headImge.sd_setImage(with: URL(string: imageName), completed: nil)
      } else {
        headImge.setTitle(conversationModel.userInfo?.showName() ?? "")
        headImge.sd_setImage(with: nil, completed: nil)
        headImge.backgroundColor = UIColor
          .colorWithString(string: conversationModel.userInfo?.userId)
      }

      // p2p nickName
      title.text = conversationModel.userInfo?.showName()

      // notifyForNewMsg
      notifyMsg.isHidden = viewModel
        .notifyForNewMsg(userId: conversationModel.userInfo?.userId)

    } else if conversationModel.recentSession?.session?.sessionType == .team {
      // team head image
      if let imageName = conversationModel.teamInfo?.avatarUrl {
        headImge.setTitle("")
        headImge.sd_setImage(with: URL(string: imageName), completed: nil)
      } else {
        headImge.setTitle(conversationModel.teamInfo?.getShowName() ?? "")
        headImge.sd_setImage(with: nil, completed: nil)
        headImge.backgroundColor = UIColor
          .colorWithString(string: conversationModel.teamInfo?.teamId)
      }
      title.text = conversationModel.teamInfo?.getShowName()

      // notifyForNewMsg
      let teamNotifyState = viewModel
        .notifyStateForNewMsg(teamId: conversationModel.teamInfo?.teamId)
      notifyMsg.isHidden = teamNotifyState == .none ? false : true
    }

    // last message
    if let lastMessage = conversationModel.recentSession?.lastMessage {
      subTitle.text = contentForRecentSession(message: lastMessage)
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
    }

    // backgroundColor
    if let session = conversationModel.recentSession?.session {
      let isTop = topStickInfos[session] != nil
      if isTop {
        contentView.backgroundColor = UIColor(hexString: "0xF3F5F7")
      } else {
        contentView.backgroundColor = .white
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
      fmt.dateFormat = "HH:mm"
      return fmt.string(from: targetDate)

    } else {
      if targetDate.isThisYear() {
        fmt.dateFormat = "MM月dd日 HH:mm"
        return fmt.string(from: targetDate)

      } else {
        fmt.dateFormat = "yyyy年MM月dd日 HH:mm"
        return fmt.string(from: targetDate)
      }
    }
  }

  func contentForRecentSession(message: NIMMessage) -> String {
    let text = NEMessageUtil.messageContent(message: message)
    return text
  }

  // MARK: lazy Method

  lazy var headImge: NEUserHeaderView = {
    let headView = NEUserHeaderView(frame: .zero)
    headView.titleLabel.textColor = .white
    headView.titleLabel.font = NEConstant.defaultTextFont(14)
    headView.translatesAutoresizingMaskIntoConstraints = false
    headView.layer.cornerRadius = 21
    headView.clipsToBounds = true
    return headView
  }()

  private lazy var redAngleView: RedAngleLabel = {
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

  private lazy var title: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEKitConversationConfig.shared.ui.titleColor
    label.font = NEKitConversationConfig.shared.ui.titleFont
    label.text = "Oliver"
    return label
  }()

  private lazy var subTitle: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEKitConversationConfig.shared.ui.subTitleColor
    label.font = NEKitConversationConfig.shared.ui.subTitleFont
    return label
  }()

  private lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEKitConversationConfig.shared.ui.timeColor
    label.font = NEKitConversationConfig.shared.ui.timeFont
    label.textAlignment = .right
    return label
  }()

  private lazy var notifyMsg: UIImageView = {
    let notify = UIImageView()
    notify.translatesAutoresizingMaskIntoConstraints = false
    notify.image = UIImage.ne_imageNamed(name: "noNeed_notify")
    notify.isHidden = true
    return notify
  }()
}
