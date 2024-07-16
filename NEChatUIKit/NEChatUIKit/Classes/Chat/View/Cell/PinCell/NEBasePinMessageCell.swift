// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECommonUIKit
import NIMSDK
import UIKit

@objc
public protocol PinMessageCellDelegate {
  func didClickMore(_ model: NEPinMessageModel?)
  func didClickContent(_ model: NEPinMessageModel?, _ cell: NEBasePinMessageCell)
}

@objcMembers
open class NEBasePinMessageCell: UITableViewCell {
  public var contentWidth: NSLayoutConstraint?

  public var contentHeight: NSLayoutConstraint?

  public var pinModel: NEPinMessageModel?

  public var delegate: PinMessageCellDelegate?

  public var contentGesture: UITapGestureRecognizer?

  public lazy var headerView: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.titleLabel.font = NEConstant.defaultTextFont(12)
    header.titleLabel.textColor = UIColor.white
    header.layer.cornerRadius = 16
    header.clipsToBounds = true
    header.translatesAutoresizingMaskIntoConstraints = false
    return header
  }()

  public lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 12.0)
    label.textColor = .ne_darkText
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  public lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 12.0)
    label.textColor = .ne_greyText
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.time"
    return label
  }()

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
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  open func setupUI() {
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
    let imageView = UIImageView()
    imageView.image = image
    imageView.translatesAutoresizingMaskIntoConstraints = false
    backView.addSubview(imageView)

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
      imageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
      imageView.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -20),
    ])

    backView.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: headerView.rightAnchor, constant: 8),
      nameLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
      nameLabel.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -50),
    ])

    backView.addSubview(timeLabel)
    NSLayoutConstraint.activate([
      timeLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
      timeLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor),
      timeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
    ])

    backView.addSubview(line)
    line.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      line.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16),
      line.rightAnchor.constraint(equalTo: backView.rightAnchor, constant: -16),
      line.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
      line.heightAnchor.constraint(equalToConstant: 1),
    ])
    line.backgroundColor = .ne_greyLine
  }

  open func configure(_ item: NEPinMessageModel) {
    pinModel = item
    headerView.configHeadData(headUrl: item.chatmodel.avatar,
                              name: item.chatmodel.shortName ?? "",
                              uid: ChatMessageHelper.getSenderId(item.chatmodel.message) ?? "")
    nameLabel.text = item.chatmodel.fullName
    timeLabel.text = String.stringFromDate(date: Date(timeIntervalSince1970: item.message.createTime))

    contentWidth?.constant = item.chatmodel.contentSize.width
    contentHeight?.constant = item.chatmodel.contentSize.height
  }

  func moreClick() {
    delegate?.didClickMore(pinModel)
  }

  open func contentClick() {
    delegate?.didClickContent(pinModel, self)
  }
}
