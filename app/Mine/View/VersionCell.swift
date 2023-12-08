
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NETeamUIKit
import UIKit

enum IntroduceCellType: Int {
  case version = 0
  case productIntroduce
}

class VersionCell: UITableViewCell {
  public var cellType: IntroduceCellType? {
    didSet {
      if cellType == .version {
        subTitle.isHidden = false
        arrow.isHidden = true
      } else {
        subTitle.isHidden = true
        arrow.isHidden = false
      }
    }
  }

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
    setupSubviews()
    selectionStyle = .none
  }

  func setupSubviews() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(subTitle)
    contentView.addSubview(arrow)
    contentView.addSubview(bottomLine)

    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    NSLayoutConstraint.activate([
      subTitle.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      subTitle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    NSLayoutConstraint.activate([
      arrow.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      arrow.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      bottomLine.rightAnchor.constraint(equalTo: rightAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configData(model: SettingCellModel) {
    titleLabel.text = model.cellName
    subTitle.text = model.subTitle
  }

  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(hexString: "0x333333")
    label.font = UIFont.systemFont(ofSize: 14)
    return label
  }()

  lazy var subTitle: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(hexString: "0x333333")
    label.font = UIFont.systemFont(ofSize: 14)
    label.isHidden = true
    label.accessibilityIdentifier = "id.version"
    return label
  }()

  public lazy var arrow: UIImageView = {
    let imageView = UIImageView(image: UIImage(named: "arrow_right"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.isHidden = true
    return imageView
  }()

  private lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "0xDBE0E8")
    return view
  }()
}
