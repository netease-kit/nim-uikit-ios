
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import UIKit

@objcMembers
open class UserBaseTableViewCell: UITableViewCell {
  /// 用户头像
  public lazy var avatarImageView: UIImageView = {
    let avatarImageView = UIImageView()
    avatarImageView.backgroundColor = UIColor(hexString: "#537FF4")
    avatarImageView.translatesAutoresizingMaskIntoConstraints = false
    avatarImageView.clipsToBounds = true
    avatarImageView.isUserInteractionEnabled = true
    avatarImageView.contentMode = .scaleAspectFill
    avatarImageView.accessibilityIdentifier = "id.avatar"
    return avatarImageView
  }()

  public lazy var nameLabel: UILabel = {
    let nameLabel = UILabel()
    nameLabel.textAlignment = .center
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.font = UIFont.systemFont(ofSize: 12)
    nameLabel.textColor = .white
    nameLabel.text = "placeholder"
    nameLabel.accessibilityIdentifier = "id.avatar"
    return nameLabel
  }()

  public lazy var titleLabel: UILabel = {
    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = "placeholder"
    titleLabel.accessibilityIdentifier = "id.nickname"
    return titleLabel
  }()

  public var userModel: NETeamMemberInfoModel?

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .white
    baseCommonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func baseCommonUI() {
    selectionStyle = .none
    backgroundColor = .white
    contentView.addSubview(avatarImageView)
    contentView.addSubview(nameLabel)
    contentView.addSubview(titleLabel)

    // name
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: avatarImageView.leftAnchor),
      nameLabel.rightAnchor.constraint(equalTo: avatarImageView.rightAnchor),
      nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
      nameLabel.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
    ])

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = "placeholder"
  }

  open func setModel(_ model: NETeamMemberInfoModel) {
    userModel = model
    nameLabel.text = NEFriendUserCache.getShortName(model.showNickInTeam() ?? "")
    titleLabel.text = model.atNameInTeam()

    if let avatarURL = model.nimUser?.user?.avatar, !avatarURL.isEmpty {
      avatarImageView
        .sd_setImage(with: URL(string: avatarURL)) { [weak self] image, error, type, url in
          if image != nil {
            self?.avatarImageView.image = image
            self?.nameLabel.isHidden = true
            self?.avatarImageView.backgroundColor = .clear
          } else {
            self?.avatarImageView.image = nil
            self?.nameLabel.isHidden = false
            self?.avatarImageView.backgroundColor = UIColor.colorWithString(string: model.teamMember?.accountId)
          }
        }
    } else {
      avatarImageView.image = nil
      nameLabel.isHidden = false
      avatarImageView.backgroundColor = UIColor.colorWithString(string: model.teamMember?.accountId)
    }
  }
}
