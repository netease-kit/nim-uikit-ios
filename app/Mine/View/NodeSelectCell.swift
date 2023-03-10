
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NETeamUIKit

class NodeSelectCell: CornerCell {
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
    fatalError("init(coder:) has not been implemented")
  }

  public func configure(_ cellModel: SettingCellModel) {
    cornerType = cellModel.cornerType
    stateImg.isHighlighted = cellModel.switchOpen ? true : false
    titleLabel.text = cellModel.subTitle
  }

  func setupUI() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(stateImg)

    NSLayoutConstraint.activate([
      stateImg.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      stateImg.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 30),
    ])

    NSLayoutConstraint.activate([
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      titleLabel.leftAnchor.constraint(equalTo: stateImg.rightAnchor, constant: 10),
    ])
  }

  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textColor = UIColor.ne_darkText
    label.font = NEConstant.defaultTextFont(14.0)
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  lazy var stateImg: UIImageView = {
    let img = UIImageView()
    img.image = UIImage(named: "unselect")
    img.highlightedImage = UIImage(named: "select")
    img.translatesAutoresizingMaskIntoConstraints = false
    return img
  }()
}
