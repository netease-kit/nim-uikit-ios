
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ChatImageTextCell: ChatStateCell {
  var circleView = UIImageView()
  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    // circle view
    circleView.translatesAutoresizingMaskIntoConstraints = false
    circleView.layer.cornerRadius = 16
    circleView.clipsToBounds = true
    circleView.backgroundColor = .ne_defautAvatarColor
    contentView.addSubview(circleView)
    NSLayoutConstraint.activate([
      circleView.widthAnchor.constraint(equalToConstant: 36),
      circleView.heightAnchor.constraint(equalToConstant: 36),
      circleView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 40),
      circleView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])
//        short name label
    contentView.addSubview(shortNameLabel)
    NSLayoutConstraint.activate([
      shortNameLabel.widthAnchor.constraint(equalTo: circleView.widthAnchor),
      shortNameLabel.heightAnchor.constraint(equalTo: circleView.heightAnchor),
      shortNameLabel.leftAnchor.constraint(equalTo: circleView.leftAnchor),
      shortNameLabel.topAnchor.constraint(equalTo: circleView.topAnchor),
    ])
//        name label
    contentView.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: circleView.rightAnchor, constant: 12),
      nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
//        line
    let line = UIView()
    line.backgroundColor = .ne_greyLine
    line.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(line)
    NSLayoutConstraint.activate([
      line.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      line.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      line.heightAnchor.constraint(equalToConstant: 1),
      line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -1),
    ])
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public lazy var avatarImage: UIImageView = {
    let avatar = UIImageView()
    avatar.translatesAutoresizingMaskIntoConstraints = false
    avatar.clipsToBounds = true
    avatar.backgroundColor = .ne_defautAvatarColor
    return avatar
  }()

  public lazy var shortNameLabel: UILabel = {
    let name = UILabel()
    name.translatesAutoresizingMaskIntoConstraints = false
    name.textColor = .white
    name.textAlignment = .center
    name.font = UIFont.systemFont(ofSize: 14.0)
    return name
  }()

  public lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.textColor = .ne_darkText
    return label
  }()

  open func setup(accid: String?, nickName: String?) {
    let name = nickName?.count ?? 0 > 0 ? nickName : accid
    nameLabel.text = name
    guard let n = name else { return }
    shortNameLabel.text = n.count > 2 ? String(n[n.index(n.endIndex, offsetBy: -2)...]) : n
    circleView.backgroundColor = UIColor.colorWithString(string: accid)
  }
}
