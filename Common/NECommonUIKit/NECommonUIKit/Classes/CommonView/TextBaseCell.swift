
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class TextBaseCell: UITableViewCell {
  public var titleLabelTopAnchor: NSLayoutConstraint?
  public var titleLabelCenterYAnchor: NSLayoutConstraint?

  /// 头像视图
  public lazy var headImageView: NEUserHeaderView = {
    let headView = NEUserHeaderView(frame: .zero)
    headView.titleLabel.textColor = .white
    headView.titleLabel.font = UIFont.systemFont(ofSize: 14)
    headView.translatesAutoresizingMaskIntoConstraints = false
    headView.layer.cornerRadius = 18
    headView.clipsToBounds = true
    return headView
  }()

  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_darkText
    label.font = UIFont.systemFont(ofSize: 14)
    label.accessibilityIdentifier = "id.nickName"
    return label
  }()

  public lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.ne_greyText
    label.font = UIFont.systemFont(ofSize: 12)
    label.isHidden = true
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  override open func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupSubviews()
  }

  open func setupSubviews() {
    selectionStyle = .none
    contentView.addSubview(headImageView)
    contentView.addSubview(titleLabel)
    contentView.addSubview(subTitleLabel)

    NSLayoutConstraint.activate([
      headImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      headImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headImageView.widthAnchor.constraint(equalToConstant: 36),
      headImageView.heightAnchor.constraint(equalToConstant: 36),
    ])

    titleLabelTopAnchor = titleLabel.topAnchor.constraint(equalTo: headImageView.topAnchor)
    titleLabelCenterYAnchor = titleLabel.centerYAnchor.constraint(equalTo: headImageView.centerYAnchor)
    titleLabelCenterYAnchor?.isActive = true
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: headImageView.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
    ])

    NSLayoutConstraint.activate([
      subTitleLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor, constant: 0),
      subTitleLabel.rightAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 0),
      subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
    ])
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
}
