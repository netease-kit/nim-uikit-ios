// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEContactUIKit

public class CustomContactTableViewCell: ContactTableViewCell {
  private lazy var onlineView: UIImageView = {
    let notify = UIImageView()
    notify.translatesAutoresizingMaskIntoConstraints = false
    notify.image = UIImage(named: "about_yunxin")
    notify.isHidden = true
    return notify
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    contentView.addSubview(onlineView)
    NSLayoutConstraint.activate([
      onlineView.rightAnchor.constraint(equalTo: avatarImage.rightAnchor),
      onlineView.bottomAnchor.constraint(equalTo: avatarImage.bottomAnchor),
      onlineView.widthAnchor.constraint(equalToConstant: 12),
      onlineView.heightAnchor.constraint(equalToConstant: 12),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func setModel(_ model: ContactInfo) {
    super.setModel(model)
    onlineView.isHidden = false
  }
}
