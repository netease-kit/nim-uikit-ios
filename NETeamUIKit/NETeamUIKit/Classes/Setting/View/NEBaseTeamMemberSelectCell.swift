//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

@objcMembers
open class NEBaseTeamMemberSelectCell: UITableViewCell {
  // check box image
  public lazy var checkImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    imageView.image = coreLoader.loadImage("unselect")
    return imageView
  }()

  public lazy var headerView: NEUserHeaderView = {
    let headerView = NEUserHeaderView(frame: .zero)
    headerView.titleLabel.font = NEConstant.defaultTextFont(14)
    headerView.titleLabel.textColor = UIColor.white
    headerView.clipsToBounds = true
    headerView.translatesAutoresizingMaskIntoConstraints = false
    headerView.accessibilityIdentifier = "id.avatar"
    return headerView
  }()

  public lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(16.0)
    label.textColor = .ne_darkText
    label.accessibilityIdentifier = "id.userName"
    return label
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupUI() {
    contentView.addSubview(headerView)
    contentView.addSubview(nameLabel)
    contentView.addSubview(checkImageView)
  }

  open func configureMember(_ model: NESelectTeamMember?) {
    checkImageView.isHighlighted = model?.isSelected ?? false
    if let url = model?.member?.nimUser?.user?.avatar, !url.isEmpty {
      headerView.sd_setImage(with: URL(string: url), completed: nil)
      headerView.setTitle("")
    } else {
      headerView.image = nil
      headerView.setTitle(model?.member?.showNickInTeam() ?? "")
      headerView.backgroundColor = UIColor.colorWithString(string: model?.member?.nimUser?.user?.accountId)
    }
    nameLabel.text = model?.member?.atNameInTeam()
  }
}
