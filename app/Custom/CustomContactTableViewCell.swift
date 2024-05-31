// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEContactUIKit

public class CustomContactTableViewCell: ContactTableViewCell {
  private lazy var onlineView: UIImageView = {
    let notifyView = UIImageView()
    notifyView.translatesAutoresizingMaskIntoConstraints = false
    notifyView.image = UIImage(named: "about_yunxin")
    notifyView.isHidden = true
    return notifyView
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    contentView.addSubview(onlineView)
    NSLayoutConstraint.activate([
      onlineView.rightAnchor.constraint(equalTo: avatarImageView.rightAnchor),
      onlineView.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
      onlineView.widthAnchor.constraint(equalToConstant: 12),
      onlineView.heightAnchor.constraint(equalToConstant: 12),
    ])
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  // 根据数据模型设置 cell 内容
  override public func setModel(_ model: ContactInfo) {
    super.setModel(model)
    onlineView.isHidden = false
  }
}
