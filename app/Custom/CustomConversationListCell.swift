
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEConversationUIKit
import UIKit

open class CustomConversationListCell: ConversationListCell {
  // 新增 UI 元素，用于展示在线状态
  private lazy var onlineView: UIImageView = {
    let notifyView = UIImageView()
    notifyView.translatesAutoresizingMaskIntoConstraints = false
    notifyView.image = UIImage(named: "about_yunxin")
    return notifyView
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    // 头像右下角
    contentView.addSubview(onlineView)
    NSLayoutConstraint.activate([
      onlineView.rightAnchor.constraint(equalTo: headImageView.rightAnchor),
      onlineView.bottomAnchor.constraint(equalTo: headImageView.bottomAnchor),
      onlineView.widthAnchor.constraint(equalToConstant: 12),
      onlineView.heightAnchor.constraint(equalToConstant: 12),
    ])
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  // 此方法用于数据和 UI 的绑定，可在此处在数据展示前对数据进行处理
  override open func configureData(_ sessionModel: NEConversationListModel?) {
    super.configureData(sessionModel)
    //    subTitle.text = "[自定义类型文案]"
  }
}
