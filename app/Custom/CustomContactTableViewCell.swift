// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEContactUIKit

public class CustomContactTableViewCell: ContactTableViewCell {
  private lazy var redDotView: UIImageView = {
    let notifyView = UIImageView()
    notifyView.translatesAutoresizingMaskIntoConstraints = false
    notifyView.backgroundColor = .red
    notifyView.layer.cornerRadius = 6
    notifyView.isHidden = true
    return notifyView
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    contentView.addSubview(redDotView)
    NSLayoutConstraint.activate([
      redDotView.rightAnchor.constraint(equalTo: userHeaderView.rightAnchor),
      redDotView.topAnchor.constraint(equalTo: userHeaderView.topAnchor),
      redDotView.widthAnchor.constraint(equalToConstant: 12),
      redDotView.heightAnchor.constraint(equalToConstant: 12),
    ])
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  // 根据数据模型设置 cell 内容
  override open func setModel(_ model: ContactInfo) {
    super.setModel(model)
    redDotView.isHidden = false
  }
}
