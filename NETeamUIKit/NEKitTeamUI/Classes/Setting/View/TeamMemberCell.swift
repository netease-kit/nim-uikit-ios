
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitTeam
import NEKitCommonUI

class TeamMemberCell: UITableViewCell {
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
    label.clipsToBounds = true
    label.layer.cornerRadius = 4.0
    label.layer.borderColor = NEConstant.hexRGB(0xB9D3FF).cgColor
    label.layer.borderWidth = 1.0
    label.text = "群主"
    label.textAlignment = .center
    return label
  }()

  lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(16.0)
    label.textColor = .ne_darkText
    return label
  }()

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    contentView.addSubview(headerView)
    NSLayoutConstraint.activate([
      headerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 21),
      headerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headerView.widthAnchor.constraint(equalToConstant: 42),
      headerView.heightAnchor.constraint(equalToConstant: 42),
    ])

    contentView.addSubview(ownerLabel)
    NSLayoutConstraint.activate([
      ownerLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      ownerLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      ownerLabel.heightAnchor.constraint(equalToConstant: 25.0),
      ownerLabel.widthAnchor.constraint(equalToConstant: 48.0),
    ])

    contentView.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: headerView.rightAnchor, constant: 14.0),
      nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      nameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -70),
    ])
  }

  func configure(_ model: TeamMemberInfoModel) {
//        ownerLabel.isHidden = !isOwner(model.nimUser?.userId)
    if let url = model.nimUser?.userInfo?.avatarUrl {
      headerView.sd_setImage(with: URL(string: url), completed: nil)
      headerView.setTitle("")
    } else {
      headerView.image = nil
      headerView.setTitle(model.showNameInTeam())
      headerView.backgroundColor = UIColor.colorWithString(string: model.nimUser?.userId)
    }
    nameLabel.text = model.showNameInTeam()
  }
}
