
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECommonKit
import NIMSDK
import NECoreIMKit
import NECoreKit
import NETeamKit

@objcMembers
public class TeamUserCell: UICollectionViewCell {
  var user: TeamMemberInfoModel? {
    didSet {
      if let name = user?.showNickInTeam() {
        userHeader.setTitle(name)
      }
      if let url = user?.nimUser?.userInfo?.avatarUrl {
        userHeader.sd_setImage(with: URL(string: url), completed: nil)
        userHeader.setTitle("")
      } else if let id = user?.nimUser?.userId {
        userHeader.image = nil
        userHeader.backgroundColor = UIColor.colorWithString(string: "\(id)")
      }
    }
  }

  lazy var userHeader: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.translatesAutoresizingMaskIntoConstraints = false
    header.titleLabel.font = NEConstant.defaultTextFont(11.0)
    header.clipsToBounds = true
    header.layer.cornerRadius = 16.0
    return header
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    contentView.addSubview(userHeader)
    NSLayoutConstraint.activate([
      userHeader.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      userHeader.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      userHeader.widthAnchor.constraint(equalToConstant: 32.0),
      userHeader.heightAnchor.constraint(equalToConstant: 32.0),
    ])
  }
}
