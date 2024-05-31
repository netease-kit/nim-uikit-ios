
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NETeamUIKit
import UIKit

class NodeSelectCell: CornerCell {
  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textColor = UIColor.ne_darkText
    label.font = NEConstant.defaultTextFont(14.0)
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  lazy var stateImageView: UIImageView = {
    let imgView = UIImageView()
    imgView.image = UIImage(named: "unselect")
    imgView.highlightedImage = UIImage(named: "select")
    imgView.translatesAutoresizingMaskIntoConstraints = false
    return imgView
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

  public func configure(_ cellModel: SettingCellModel) {
    cornerType = cellModel.cornerType
    stateImageView.isHighlighted = cellModel.switchOpen ? true : false
    titleLabel.text = cellModel.subTitle
  }

  func setupUI() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(stateImageView)

    NSLayoutConstraint.activate([
      stateImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      stateImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 30),
    ])

    NSLayoutConstraint.activate([
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      titleLabel.leftAnchor.constraint(equalTo: stateImageView.rightAnchor, constant: 10),
    ])
  }
}
