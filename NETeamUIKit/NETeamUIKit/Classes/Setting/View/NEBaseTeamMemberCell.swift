
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

protocol TeamMemberCellDelegate: NSObject {
  func didClickRemoveButton(_ model: TeamMemberInfoModel?, _ index: Int)
}

@objcMembers
open class NEBaseTeamMemberCell: UITableViewCell {
  var currentModel: TeamMemberInfoModel?

  weak var delegate: TeamMemberCellDelegate?

  public var ownerWidth: NSLayoutConstraint?

  public var nameLabelRightMargin: NSLayoutConstraint?

  var index = 0

  lazy var headerView: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.titleLabel.font = NEConstant.defaultTextFont(14)
    header.titleLabel.textColor = UIColor.white
    header.layer.cornerRadius = 21
    header.clipsToBounds = true
    header.translatesAutoresizingMaskIntoConstraints = false
    return header
  }()

  lazy var ownerLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(12.0)
    label.textColor = NEConstant.hexRGB(0x337EFF)
    label.backgroundColor = NEConstant.hexRGB(0xE0ECFF)
    label.layer.borderColor = NEConstant.hexRGB(0xB9D3FF).cgColor
    label.clipsToBounds = true
    label.layer.cornerRadius = 4.0
    label.layer.borderWidth = 1.0
    label.text = localizable("team_owner")
    label.textAlignment = .center
    label.accessibilityIdentifier = "id.identify"
    return label
  }()

  lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(16.0)
    label.textColor = .ne_darkText
    label.accessibilityIdentifier = "id.userName"
    return label
  }()

  lazy var removeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = localizable("team_member_remove")
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.textAlignment = .center
    return label
  }()

  lazy var removeBtn: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupUI() {
    contentView.addSubview(headerView)
    NSLayoutConstraint.activate([
      headerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 21),
      headerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headerView.widthAnchor.constraint(equalToConstant: 42),
      headerView.heightAnchor.constraint(equalToConstant: 42),
    ])

    nameLabelRightMargin = nameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -116)
    contentView.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: headerView.rightAnchor, constant: 14.0),
      nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      nameLabelRightMargin!,
    ])

    ownerWidth = ownerLabel.widthAnchor.constraint(equalToConstant: 48.0)
    contentView.addSubview(ownerLabel)
    NSLayoutConstraint.activate([
      ownerLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -70),
      ownerLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      ownerLabel.heightAnchor.constraint(equalToConstant: 22.0),
      ownerWidth!,
    ])
  }

  func configure(_ model: TeamMemberInfoModel) {
    if let userId = model.nimUser?.userId, let user = ChatUserCache.getUserInfo(userId) {
      model.nimUser = user
    }
    currentModel = model
    if let url = model.nimUser?.userInfo?.avatarUrl, !url.isEmpty {
      headerView.sd_setImage(with: URL(string: url), completed: nil)
      headerView.setTitle("")
    } else {
      headerView.image = nil
      headerView.setTitle(model.showNickInTeam())
      headerView.backgroundColor = UIColor.colorWithString(string: model.nimUser?.userId)
    }
    nameLabel.text = model.atNameInTeam()
  }

  func setupRemoveButton() {
    contentView.addSubview(removeBtn)
    NSLayoutConstraint.activate([
      removeBtn.topAnchor.constraint(equalTo: contentView.topAnchor),
      removeBtn.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      removeBtn.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      removeBtn.widthAnchor.constraint(equalToConstant: 100),
    ])
    removeBtn.addTarget(self, action: #selector(didClickRemove), for: .touchUpInside)
  }

  func didClickRemove() {
    delegate?.didClickRemoveButton(currentModel, index)
  }
}
