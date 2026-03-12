//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import UIKit

@objcMembers
open class NEBaseFusionContactSelectedCell: UITableViewCell {
  /// 用户头像
  public lazy var userHeaderView: NEUserHeaderView = {
    let imageView = NEUserHeaderView(frame: .zero)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.clipsToBounds = true
    imageView.titleLabel.font = NEConstant.defaultTextFont(14.0)
    imageView.isUserInteractionEnabled = true
    return imageView
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
    imageView.image = coreLoader.loadImage("unselect")
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

      let url = model.user?.user?.avatar
      let name = model.user?.shortName() ?? ""
      let accountId = model.user?.user?.accountId ?? ""
      userHeaderView.configHeadData(headUrl: url, name: name, uid: accountId)
    } else if model.aiUser != nil {
      nameLabel.text = model.aiUser?.showName()

      let url = model.aiUser?.avatar
      let name = model.aiUser?.shortName() ?? ""
      let accountId = model.aiUser?.accountId ?? ""
      userHeaderView.configHeadData(headUrl: url, name: name, uid: accountId)
    }

    selectedStateImage.isHighlighted = model.selected
  }
}
