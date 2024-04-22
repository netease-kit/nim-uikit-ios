
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
  /// 标题
  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(hexString: "0x333333")
    label.font = UIFont.systemFont(ofSize: 14)
    return label
  }()

  /// 子标题
  lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(hexString: "0x333333")
    label.font = UIFont.systemFont(ofSize: 14)
    label.isHidden = true
    label.accessibilityIdentifier = "id.version"
    return label
  }()

  /// 箭头图片
  public lazy var arrowImageView: UIImageView = {
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

  public var cellType: IntroduceCellType? {
    didSet {
      if cellType == .version {
        subTitleLabel.isHidden = false
        arrowImageView.isHidden = true
      } else {
        subTitleLabel.isHidden = true
        arrowImageView.isHidden = false
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
    contentView.addSubview(subTitleLabel)
    contentView.addSubview(arrowImageView)
    contentView.addSubview(bottomLine)

    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    NSLayoutConstraint.activate([
      subTitleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      subTitleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    NSLayoutConstraint.activate([
      arrowImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      bottomLine.rightAnchor.constraint(equalTo: rightAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func configData(model: SettingCellModel) {
    titleLabel.text = model.cellName
    subTitleLabel.text = model.subTitle
  }
}
