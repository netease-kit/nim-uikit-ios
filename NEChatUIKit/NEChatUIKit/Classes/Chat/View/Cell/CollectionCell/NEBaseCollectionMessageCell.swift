//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import UIKit

@objc
public protocol CollectionMessageCellDelegate {
  func didClickMore(_ model: CollectionMessageModel?)
  func didClickContent(_ model: CollectionMessageModel?, _ cell: NEBaseCollectionMessageCell)
}

@objcMembers
open class NEBaseCollectionMessageCell: UITableViewCell {
  public var contentWidth: NSLayoutConstraint?

  public var contentHeight: NSLayoutConstraint?

  public var collectionModel: CollectionMessageModel?

  public var delegate: CollectionMessageCellDelegate?

  public var contentGesture: UITapGestureRecognizer?

  /// 头像
  public lazy var headerView: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.titleLabel.font = NEConstant.defaultTextFont(12)
    header.titleLabel.textColor = UIColor.white
    header.layer.cornerRadius = 16
    header.clipsToBounds = true
    header.translatesAutoresizingMaskIntoConstraints = false
    return header
  }()

  /// 消息发送者昵称
  public lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.textColor = .ne_darkText
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  /// 时间
  public lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 12.0)
    label.textColor = .ne_greyText
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.time"
    return label
  }()

  /// 会话标签
  public lazy var conversationLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.textColor = .ne_greyText
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.conversation"
    return label
  }()

  /// 更多
  public let moreImageView = UIImageView()

  public let backView = UIView()

  public let line = UIView()

  public var backLeftConstraint: NSLayoutConstraint?
  public var backRightConstraint: NSLayoutConstraint?

  override open func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .clear
    contentGesture = UITapGestureRecognizer(target: self, action: #selector(contentClick))
    setupCommonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  /// UI 初始化
  open func setupCommonUI() {
    contentView.backgroundColor = .clear

    backView.translatesAutoresizingMaskIntoConstraints = false
    backView.backgroundColor = UIColor.white
    backView.clipsToBounds = true
    backView.layer.cornerRadius = 8.0
    contentView.addSubview(backView)

    backLeftConstraint = backView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20)
    backLeftConstraint?.isActive = true
    backRightConstraint = backView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20)
    backRightConstraint?.isActive = true
    NSLayoutConstraint.activate([
      backView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      backView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    backView.addSubview(headerView)
    NSLayoutConstraint.activate([
      headerView.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16),
      headerView.topAnchor.constraint(equalTo: backView.topAnchor, constant: 16),
      headerView.widthAnchor.constraint(equalToConstant: 32),
      headerView.heightAnchor.constraint(equalToConstant: 32),
    ])

    let image = UIImage.ne_imageNamed(name: "three_point")
    moreImageView.image = image
    moreImageView.translatesAutoresizingMaskIntoConstraints = false
    backView.addSubview(moreImageView)

    let moreButton = UIButton()
    moreButton.addTarget(self, action: #selector(moreClick), for: .touchUpInside)
    moreButton.accessibilityIdentifier = "id.moreAction"
    moreButton.translatesAutoresizingMaskIntoConstraints = false
    backView.addSubview(moreButton)
    NSLayoutConstraint.activate([
      moreButton.rightAnchor.constraint(equalTo: backView.rightAnchor),
      moreButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
      moreButton.widthAnchor.constraint(equalToConstant: 50),
      moreButton.heightAnchor.constraint(equalToConstant: 40),
    ])

    NSLayoutConstraint.activate([
      moreImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
      moreImageView.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -20),
    ])

    backView.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: headerView.rightAnchor, constant: 8),
      nameLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
      nameLabel.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -50),
    ])

    backView.addSubview(timeLabel)
    NSLayoutConstraint.activate([
      timeLabel.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16),
      timeLabel.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16),
      timeLabel.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -12),
    ])

    backView.addSubview(line)
    line.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      line.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16),
      line.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16),
      line.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -38),
      line.heightAnchor.constraint(equalToConstant: 1),
    ])
    line.backgroundColor = .ne_greyLine

    backView.addSubview(conversationLabel)
    NSLayoutConstraint.activate([
      conversationLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
      conversationLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor),
      conversationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
    ])
  }

  /// 数据源绑定
  /// - Parameter model: 数据模型
  open func configureData(_ model: CollectionMessageModel) {
    collectionModel = model
    headerView.configHeadData(headUrl: model.chatmodel.avatar,
                              name: model.chatmodel.fullName ?? "",
                              uid: ChatMessageHelper.getSenderId(model.chatmodel.message) ?? "")
    nameLabel.text = model.chatmodel.fullName
    if let time = model.collection?.updateTime {
      timeLabel.text = String.stringFromDate(date: Date(timeIntervalSince1970: time))
    } else if let time = model.message?.createTime {
      timeLabel.text = String.stringFromDate(date: Date(timeIntervalSince1970: time))
    }

    if model.message?.conversationType == .CONVERSATION_TYPE_P2P {
      if let conversationName = model.conversationName {
        conversationLabel.text = String(format: chatLocalizable("chat_collection_p2p_tip"), conversationName)
      }
    } else if model.message?.conversationType == .CONVERSATION_TYPE_TEAM || model.message?.conversationType == .CONVERSATION_TYPE_SUPER_TEAM {
      if let conversationName = model.conversationName {
        conversationLabel.text = String(format: chatLocalizable("chat_collection_team_tip"), conversationName)
      }
    }

    contentWidth?.constant = model.chatmodel.contentSize.width
    contentHeight?.constant = model.chatmodel.contentSize.height
  }

  func moreClick() {
    delegate?.didClickMore(collectionModel)
  }

  open func contentClick() {
    delegate?.didClickContent(collectionModel, self)
  }

  /// 设置娱乐版边距
  open func setFunStyle() {
    backLeftConstraint?.constant = 0
    backRightConstraint?.constant = 0
    backView.layer.cornerRadius = 0
    headerView.layer.cornerRadius = 4.0
  }
}
