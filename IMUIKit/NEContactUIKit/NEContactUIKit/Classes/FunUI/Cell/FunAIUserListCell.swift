//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunAIUserListCell: NEBaseAIUserListCell {
  /// 列表分隔线
  public var dividerLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.funContactDividerLineColor
    return view
  }()

  /// 通用版UI初始化
  override open func setupAIUserListCellUI() {
    contentView.addSubview(aiUserHeaderView)
    NSLayoutConstraint.activate([
      aiUserHeaderView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 21),
      aiUserHeaderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      aiUserHeaderView.widthAnchor.constraint(equalToConstant: 40),
      aiUserHeaderView.heightAnchor.constraint(equalToConstant: 40),
    ])
    aiUserHeaderView.layer.cornerRadius = 4.0

    contentView.addSubview(aiUserNameLabel)
    NSLayoutConstraint.activate([
      aiUserNameLabel.leftAnchor.constraint(equalTo: aiUserHeaderView.rightAnchor, constant: 14.0),
      aiUserNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      aiUserNameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -21),
    ])

    contentView.addSubview(dividerLine)
    NSLayoutConstraint.activate([
      dividerLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      dividerLine.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
      dividerLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      dividerLine.heightAnchor.constraint(equalToConstant: 1),
    ])
  }
}
