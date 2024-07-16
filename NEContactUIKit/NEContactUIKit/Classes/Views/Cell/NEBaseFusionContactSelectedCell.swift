//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import UIKit

@objcMembers
open class NEBaseFusionContactSelectedCell: UITableViewCell {
  /// 用户头像
  public lazy var avatarImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.clipsToBounds = true
    imageView.contentMode = .scaleAspectFill
    imageView.backgroundColor = UIColor.colorWithNumber(number: 0)
    imageView.accessibilityIdentifier = "id.avatar"
    return imageView
  }()

  /// 没有头像的头像覆盖Label
  public lazy var avatarNameLabel: UILabel = {
    let nameLabel = UILabel()
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.textColor = .white
    nameLabel.textAlignment = .center
    nameLabel.font = UIFont.systemFont(ofSize: 14.0)
    nameLabel.adjustsFontSizeToFitWidth = true
    nameLabel.accessibilityIdentifier = "id.noAvatar"
    return nameLabel
  }()

  /// 用户名展示标签
  public lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.textColor = UIColor(hexString: "333333")
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  /// 选中图片
  let selectedStateImage: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage.ne_imageNamed(name: "unselect")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.accessibilityIdentifier = "id.selector"
    return imageView
  }()

  /// 分隔线
  public lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupFusionSelectedCellUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// UI 初始化，在子类中实现
  open func setupFusionSelectedCellUI() {}

  /// 绑定数据
  open func configFusionModel(_ model: NEFusionContactCellModel) {
    if model.user != nil {
      nameLabel.text = model.user?.showName()
      avatarNameLabel.text = model.user?.shortName(showAlias: false, count: 2)
      if let imageUrl = model.user?.user?.avatar, !imageUrl.isEmpty {
        avatarNameLabel.isHidden = true
        avatarImageView.sd_setImage(with: URL(string: imageUrl), completed: nil)
      } else {
        avatarNameLabel.isHidden = false
        avatarImageView.sd_setImage(with: nil)
        avatarImageView.backgroundColor = UIColor.colorWithString(string: model.user?.user?.accountId ?? "")
      }
    } else if model.aiUser != nil {
      nameLabel.text = model.aiUser?.showName()
      avatarNameLabel.text = model.aiUser?.shortName()
      if let imageUrl = model.aiUser?.avatar, !imageUrl.isEmpty {
        avatarNameLabel.isHidden = true
        avatarImageView.sd_setImage(with: URL(string: imageUrl), completed: nil)
      } else {
        avatarNameLabel.isHidden = false
        avatarImageView.sd_setImage(with: nil)
        avatarImageView.backgroundColor = UIColor.colorWithString(string: model.aiUser?.accountId ?? "")
      }
    }

    selectedStateImage.isHighlighted = model.selected
  }
}
