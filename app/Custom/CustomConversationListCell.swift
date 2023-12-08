
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEConversationUIKit
import UIKit

open class CustomConversationListCell: ConversationListCell {
  private lazy var onlineView: UIImageView = {
    let notify = UIImageView()
    notify.translatesAutoresizingMaskIntoConstraints = false
    notify.image = UIImage(named: "about_yunxin")
    return notify
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    contentView.addSubview(onlineView)
    NSLayoutConstraint.activate([
      onlineView.rightAnchor.constraint(equalTo: headImge.rightAnchor),
      onlineView.bottomAnchor.constraint(equalTo: headImge.bottomAnchor),
      onlineView.widthAnchor.constraint(equalToConstant: 12),
      onlineView.heightAnchor.constraint(equalToConstant: 12),
    ])
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func configData(sessionModel: ConversationListModel?) {
    super.configData(sessionModel: sessionModel)
//        subTitle.text = "[自定义类型文案]"
  }
}
