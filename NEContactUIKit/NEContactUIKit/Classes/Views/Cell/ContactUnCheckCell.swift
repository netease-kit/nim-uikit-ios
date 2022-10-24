// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECommonUIKit

@objcMembers
public class ContactUnCheckCell: UICollectionViewCell {
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    contentView.addSubview(avatarImage)
    NSLayoutConstraint.activate([
      avatarImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatarImage.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      avatarImage.widthAnchor.constraint(equalToConstant: 36),
      avatarImage.heightAnchor.constraint(equalToConstant: 36),
    ])
  }

  lazy var avatarImage: NEUserHeaderView = {
    let view = NEUserHeaderView(frame: .zero)
    view.titleLabel.font = UIFont.systemFont(ofSize: 16.0)
    view.layer.cornerRadius = 18
    view.clipsToBounds = true
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  func configure(_ model: ContactInfo) {
    avatarImage.configHeadData(
      headUrl: model.user?.userInfo?.avatarUrl,
      name: model.user?.showName() ?? ""
    )
  }
}
