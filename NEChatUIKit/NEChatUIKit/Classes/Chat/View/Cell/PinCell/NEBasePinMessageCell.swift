//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK
import NECommonUIKit
import NECommonKit

@objc
public protocol PinMessageCellDelegate {
  func didClickMore(_ model: PinMessageModel?)
}

@objcMembers
open class NEBasePinMessageCell: UITableViewCell {
  public var contentWidth: NSLayoutConstraint?

  public var contentHeight: NSLayoutConstraint?

  public var pinModel: PinMessageModel?

  public var delegate: PinMessageCellDelegate?

  lazy var headerView: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.titleLabel.font = NEConstant.defaultTextFont(12)
    header.titleLabel.textColor = UIColor.white
    header.layer.cornerRadius = 16
    header.clipsToBounds = true
    header.translatesAutoresizingMaskIntoConstraints = false
    return header
  }()

  lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 12.0)
    label.textColor = .ne_darkText
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 12.0)
    label.textColor = .ne_greyText
    label.translatesAutoresizingMaskIntoConstraints = false
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
    contentView.addSubview(backView)

    backLeftConstraint = backView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20)
    backRightConstraint = backView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20)

    NSLayoutConstraint.activate([
      backLeftConstraint!,
      backRightConstraint!,
      backView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      backView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
    backView.clipsToBounds = true
    backView.layer.cornerRadius = 8.0

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

    let moreBtn = UIButton()
    moreBtn.addTarget(self, action: #selector(moreClick), for: .touchUpInside)
    moreBtn.translatesAutoresizingMaskIntoConstraints = false
    backView.addSubview(moreBtn)
    NSLayoutConstraint.activate([
      moreBtn.rightAnchor.constraint(equalTo: backView.rightAnchor),
      moreBtn.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
      moreBtn.widthAnchor.constraint(equalToConstant: 50),
      moreBtn.heightAnchor.constraint(equalToConstant: 40),
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

  public func configure(_ item: PinMessageModel) {
    pinModel = item
    headerView.configHeadData(headUrl: item.chatmodel?.avatar,
                              name: item.chatmodel?.fullName ?? "",
                              uid: item.chatmodel?.message?.from ?? "")
    nameLabel.text = item.chatmodel?.fullName
    print("config time : ", item.message.timestamp)
    timeLabel.text = String.stringFromDate(date: Date(timeIntervalSince1970: item.message.timestamp))

    contentWidth?.constant = item.chatmodel?.contentSize.width ?? 0
    contentHeight?.constant = item.chatmodel?.contentSize.height ?? 0
  }

  func moreClick() {
    delegate?.didClickMore(pinModel)
  }
}
