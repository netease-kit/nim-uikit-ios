
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class TeamSettingSubtitleCell: BaseTeamSettingCell {
  override public func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override public func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupUI() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(subTitleLabel)
    contentView.addSubview(arrow)

    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -84),
    ])

    NSLayoutConstraint.activate([
      arrow.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      arrow.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
    ])

    NSLayoutConstraint.activate([
      subTitleLabel.rightAnchor.constraint(equalTo: arrow.leftAnchor, constant: -10),
      subTitleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      subTitleLabel.widthAnchor.constraint(equalToConstant: 200),
    ])

    titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
  }

  override public func configure(_ anyModel: Any) {
    super.configure(anyModel)
    subTitleLabel.text = model?.subTitle
  }

  lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.textColor = UIColor(hexString: "0xA6ADB6")
    label.font = NEConstant.defaultTextFont(12.0)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .right
    return label
  }()
}
