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

  func configure(_ model: ContactInfo) {
    avatarImageView.configHeadData(
      headUrl: model.user?.user?.avatar,
      name: model.user?.showName() ?? "",
      uid: model.user?.user?.accountId ?? ""
    )
  }
}
