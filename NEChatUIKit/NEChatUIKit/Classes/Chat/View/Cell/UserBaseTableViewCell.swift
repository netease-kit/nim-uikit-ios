
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import UIKit

@objcMembers
open class UserBaseTableViewCell: UITableViewCell {
  /// 用户头像
  public lazy var userHeaderView: NEUserHeaderView = {
    let imageView = NEUserHeaderView(frame: .zero)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.clipsToBounds = true
    imageView.titleLabel.font = NEConstant.defaultTextFont(14.0)
    imageView.isUserInteractionEnabled = true
    return imageView
  }()

  public lazy var titleLabel: UILabel = {
    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.accessibilityIdentifier = "id.nickname"
    return titleLabel
  }()

  public var userModel: NETeamMemberInfoModel?

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .white
    baseCommonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func baseCommonUI() {
    selectionStyle = .none
    backgroundColor = .white
    contentView.addSubview(userHeaderView)
    contentView.addSubview(titleLabel)
  }

  open func setModel(_ model: NETeamMemberInfoModel) {
    userModel = model
    titleLabel.text = model.atNameInTeam()

    let url = model.nimUser?.user?.avatar
    let name = NEFriendUserCache.getShortName(model.showNickInTeam() ?? "")
    let accountId = model.teamMember?.accountId ?? ""
    userHeaderView.configHeadData(headUrl: url, name: name, uid: accountId)
  }
}
