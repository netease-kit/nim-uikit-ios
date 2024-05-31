// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

@objcMembers
open class NEBaseContactUnCheckCell: UICollectionViewCell {
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    contentView.addSubview(avatarImageView)
  }

  lazy var avatarImageView: NEUserHeaderView = {
    let view = NEUserHeaderView(frame: .zero)
    view.titleLabel.font = UIFont.systemFont(ofSize: 16.0)
    view.clipsToBounds = true
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  /// 控件赋值方法，具体实现见子类
  /// - Parameter model: 数据模型（Any）
  func configure(_ model: Any) {}
}
