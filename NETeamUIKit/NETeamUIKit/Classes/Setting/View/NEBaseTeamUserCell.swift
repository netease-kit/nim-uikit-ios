
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseTeamUserCell: UICollectionViewCell {
  public var user: NETeamMemberInfoModel? {
    didSet {
      if let name = user?.showNickInTeam() {
        userHeaderView.setTitle(name)
      }

      if let userId = user?.nimUser?.user?.accountId {
        if let u = NEFriendUserCache.shared.getFriendInfo(userId) {
          if let url = u.user?.avatar, !url.isEmpty {
            userHeaderView.sd_setImage(with: URL(string: url), completed: nil)
            userHeaderView.setTitle("")
          } else if let id = u.user?.accountId {
            userHeaderView.image = nil
            userHeaderView.backgroundColor = UIColor.colorWithString(string: "\(id)")
          }
        } else {
          if let url = user?.nimUser?.user?.avatar, !url.isEmpty {
            userHeaderView.sd_setImage(with: URL(string: url), completed: nil)
            userHeaderView.setTitle("")
          } else if let id = user?.nimUser?.user?.accountId {
            userHeaderView.image = nil
            userHeaderView.backgroundColor = UIColor.colorWithString(string: "\(id)")
          }
        }
      }
    }
  }

  public lazy var userHeaderView: NEUserHeaderView = {
    let headerView = NEUserHeaderView(frame: .zero)
    headerView.translatesAutoresizingMaskIntoConstraints = false
    headerView.titleLabel.font = NEConstant.defaultTextFont(11.0)
    headerView.clipsToBounds = true
    return headerView
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    contentView.addSubview(userHeaderView)
  }
}
