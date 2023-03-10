
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit
import NIMSDK

@objcMembers
public class BaseValidationCell: ContactBaseViewCell {
  public var titleLabelRightMargin: NSLayoutConstraint?

  override public func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override public func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    setupCommonCircleHeader()

    addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: 10),
      titleLabel.centerYAnchor.constraint(equalTo: avatarImage.centerYAnchor),
    ])
    titleLabelRightMargin = titleLabel.rightAnchor.constraint(
      equalTo: contentView.rightAnchor,
      constant: -10
    )
    titleLabelRightMargin?.isActive = true

    let line = UIView()
    addSubview(line)
    line.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      line.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      line.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      line.heightAnchor.constraint(equalToConstant: 1),
      line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
    line.backgroundColor = UIColor(hexString: "#F5F8FC")
  }

  public func confige(_ model: XNotification) {
    var titleLabelContent = ""
    var nickName = ""
    var teamName = ""
    // 设置操作者名称

    if let alias = model.userInfo?.alias {
      nickName = alias
    } else if let nick = model.userInfo?.userInfo?.nickName {
      nickName = nick
    } else if let source = model.sourceName {
      nickName = source
    }

    if model.userInfo == nil, let uid = model.sourceID {
      let user = NIMSDK.shared().userManager.userInfo(uid)
      if let alias = user?.alias {
        nickName = alias
      } else if let nick = user?.userInfo?.nickName {
        nickName = nick
      }
    }
    // 设置头像
    if let headerUrl = model.userInfo?.userInfo?.avatarUrl, !headerUrl.isEmpty {
      avatarImage.sd_setImage(with: URL(string: headerUrl), completed: nil)
      titleLabel.text = ""
    } else if let teamUrl = model.teamInfo?.avatarUrl, !teamUrl.isEmpty {
      avatarImage.sd_setImage(with: URL(string: teamUrl), completed: nil)
      titleLabel.text = ""
    } else {
      // 无头像设置其name
      if !nickName.isEmpty {
        showNameOnCircleHeader(nickName)
      } else {
        if let id = model.sourceID {
          showNameOnCircleHeader(id)
        }
      }
      avatarImage.sd_setImage(with: URL(string: ""), completed: nil)
    }

    if let t = model.targetName {
      teamName = t
    }
    if let type = model.type {
      switch type {
      case .teamApply:
        titleLabelContent = "\(nickName) 申请入群"
      case .teamApplyReject:
        titleLabelContent = "\(nickName) 拒绝入群"
      case .teamInvite:
        titleLabelContent = "\(nickName) 邀请你加入 \(teamName)"
      case .teamInviteReject:
        titleLabelContent = "\(nickName) 拒绝入群邀请"

      case .superTeamApply:
        titleLabelContent = "\(nickName) 申请加入超大群"
      case .superTeamApplyReject:
        titleLabelContent = "\(nickName) 拒绝加入超大群"

      case .superTeamInvite:
        titleLabelContent = "\(nickName) 邀请加入 \(teamName) 群"
      case .superTeamInviteReject:
        titleLabelContent = "\(nickName) 拒绝加入 \(teamName) 群"
      case .addFriendDirectly:
        titleLabelContent = "\(nickName) 添加你为好友"
      case .addFriendRequest:
        titleLabelContent = "\(nickName) 好友申请"
      case .addFriendVerify:
        titleLabelContent = "\(nickName) 通过好友申请"
      case .addFriendReject:
        titleLabelContent = "\(nickName) 拒绝好友申请"
      @unknown default:
        titleLabelContent = "\(nickName) 未知操作"
      }
    }

    titleLabel.text = titleLabelContent
  }
}
