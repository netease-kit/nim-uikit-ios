// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import UIKit

@objcMembers
open class NEBaseTeamTableViewCell: UITableViewCell {
  public var avatarImageView = UIImageView()
  public var nameLabel = UILabel()
  public var titleLabel = UILabel()
//    public var arrow = UIImageView(image:UIImage.ne_imageNamed(name: "arrowRight"))

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func commonUI() {
    selectionStyle = .none
    avatarImageView.translatesAutoresizingMaskIntoConstraints = false
    avatarImageView.clipsToBounds = true
    avatarImageView.contentMode = .scaleAspectFill
    avatarImageView.accessibilityIdentifier = "id.avatar"
    contentView.addSubview(avatarImageView)
    NSLayoutConstraint.activate([
      avatarImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      avatarImageView.widthAnchor.constraint(equalToConstant: 42),
      avatarImageView.heightAnchor.constraint(equalToConstant: 42),
      avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])

    nameLabel.textAlignment = .center
    nameLabel.font = UIFont.systemFont(ofSize: 16)
    nameLabel.textColor = .white
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: avatarImageView.leftAnchor),
      nameLabel.rightAnchor.constraint(equalTo: avatarImageView.rightAnchor),
      nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
      nameLabel.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
    ])

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.accessibilityIdentifier = "id.name"
    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -35),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

//        self.arrow.translatesAutoresizingMaskIntoConstraints = false
//        self.arrow.isHidden = true
//        self.arrow.contentMode = .center
//        self.contentView.addSubview(self.arrow)
//        NSLayoutConstraint.activate([
//            self.arrow.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20),
//            self.arrow.widthAnchor.constraint(equalToConstant: 15),
//            self.arrow.topAnchor.constraint(equalTo: self.contentView.topAnchor),
//            self.arrow.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
//        ])
  }

  open func setModel(_ model: Any) {
    guard let team = model as? NETeam else {
      return
    }
    guard let name = team.teamName else {
      return
    }
    titleLabel.text = name
//        self.nameLabel.text = name.count > 2 ? String(name[name.index(name.endIndex, offsetBy: -2)...]) : name
    if let url = team.avatarUrl, !url.isEmpty {
      avatarImageView.sd_setImage(with: URL(string: url), completed: nil)
      avatarImageView.backgroundColor = .clear
    } else {
      // random avatar
//      avatarImage.image = randomAvatar(teamId: team.teamId)
      avatarImageView.backgroundColor = UIColor.colorWithString(string: team.teamId)
    }
  }

  private func randomAvatar(teamId: String?) -> UIImage? {
    guard let tid = teamId else {
      return nil
    }
    // mod: 0 1 2 3 4
    let mod = (Int(tid) ?? 0) % 5
    let name = "icon_" + String(mod)
    return UIImage.ne_imageNamed(name: name)
  }
}
