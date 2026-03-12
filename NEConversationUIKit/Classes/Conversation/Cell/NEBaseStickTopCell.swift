//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseStickTopCell: UICollectionViewCell {
  /// 置顶会话头像
  public lazy var stickTopHeadImageView: NEUserHeaderView = {
    let headView = NEUserHeaderView(frame: .zero)
    headView.titleLabel.textColor = .white
    headView.titleLabel.font = NEConstant.defaultTextFont(14)
    headView.translatesAutoresizingMaskIntoConstraints = false
    headView.layer.cornerRadius = 21
    headView.clipsToBounds = true
    return headView
  }()

  /// 置顶会话名称
  public lazy var stickTopNameLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(12)
    label.textColor = UIColor.ne_greyText
    label.accessibilityIdentifier = "id.name"
    label.textAlignment = .center
    return label
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupStickTopCellUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// 初始化UI
  open func setupStickTopCellUI() {
    contentView.addSubview(stickTopHeadImageView)
    contentView.addSubview(stickTopNameLabel)
  }

  /// 绑定会话数据
  /// - Parameter model: 会话数据模型
  open func configAIUserCellData(_ model: NEAIUserModel?) {
    guard let user = model?.aiUser else {
      return
    }

    let url = user.avatar
    let name = user.shortName() ?? ""
    let accountId = user.accountId ?? ""
    stickTopHeadImageView.configHeadData(headUrl: url, name: name, uid: accountId)

    if let name = user.name {
      stickTopNameLabel.text = name
    } else if let accountId = user.accountId {
      stickTopNameLabel.text = accountId
    }
  }
}
