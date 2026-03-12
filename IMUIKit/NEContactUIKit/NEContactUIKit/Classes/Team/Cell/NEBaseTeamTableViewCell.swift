// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import UIKit

@objcMembers
open class NEBaseTeamTableViewCell: UITableViewCell {
  // 头像
  public lazy var userHeaderView: NEUserHeaderView = {
    let imageView = NEUserHeaderView(frame: .zero)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.clipsToBounds = true
    imageView.titleLabel.font = NEConstant.defaultTextFont(16.0)
    imageView.isUserInteractionEnabled = true
    return imageView
  }()

  // 名称
  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  // 右侧图标
  public lazy var arrowImageView: UIImageView = {
    let arrow = UIImageView(image: coreLoader.loadImage("arrow_right"))
    arrow.translatesAutoresizingMaskIntoConstraints = false
    arrow.contentMode = .center
    arrow.isHidden = true
    return arrow
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func commonUI() {
    selectionStyle = .none

    contentView.addSubview(userHeaderView)
    NSLayoutConstraint.activate([
      userHeaderView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      userHeaderView.widthAnchor.constraint(equalToConstant: 42),
      userHeaderView.heightAnchor.constraint(equalToConstant: 42),
      userHeaderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])

    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -35),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentView.addSubview(arrowImageView)
    NSLayoutConstraint.activate([
      arrowImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      arrowImageView.widthAnchor.constraint(equalToConstant: 15),
      arrowImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      arrowImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  open func setModel(_ model: Any) {
    guard let team = model as? NETeam else {
      return
    }

    titleLabel.text = team.teamName

    let url = team.avatarUrl
    let name = team.v2Team?.getShortName() ?? ""
    let accountId = team.teamId ?? ""
    userHeaderView.configHeadData(headUrl: url, name: name, uid: accountId)
  }
}
