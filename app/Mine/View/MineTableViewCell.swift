
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

public class MineTableViewCell: UITableViewCell {
  /// 头像
  public lazy var avatarImageView: UIImageView = {
    let avatarView = UIImageView()
    avatarView.translatesAutoresizingMaskIntoConstraints = false
    return avatarView
  }()

  /// 昵称
  public lazy var titleLabel: UILabel = {
    let nameLabel = UILabel()
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.textColor = UIColor.ne_darkText
    nameLabel.font = UIFont.systemFont(ofSize: 16.0)
    nameLabel.text = NSLocalizedString("setting", comment: "")
    nameLabel.accessibilityIdentifier = "id.titleLabel"
    return nameLabel
  }()

  /// 分隔线
  private lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "0xDBE0E8")
    return view
  }()

  /// 箭头图片
  public lazy var arrowImageView: UIImageView = {
    let imageView = UIImageView(image: UIImage(named: "arrow_right"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setUpSubViews()
  }

  func setUpSubViews() {
    selectionStyle = .none
    contentView.addSubview(avatarImageView)
    contentView.addSubview(titleLabel)
    contentView.addSubview(bottomLine)
    contentView.addSubview(arrowImageView)

    NSLayoutConstraint.activate([
      avatarImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatarImageView.widthAnchor.constraint(equalToConstant: 20),
      avatarImageView.heightAnchor.constraint(equalToConstant: 20),
    ])

    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 14),
      titleLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
    ])

    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      bottomLine.rightAnchor.constraint(equalTo: rightAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])

    NSLayoutConstraint.activate([
      arrowImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -25),
//            arrow.widthAnchor.constraint(equalToConstant: 15),
      arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  func configCell(data: [String: String]) {
    titleLabel.text = data.keys.first
    if let imageName = data.values.first {
      avatarImageView.image = UIImage(named: imageName)
    }
  }
}
