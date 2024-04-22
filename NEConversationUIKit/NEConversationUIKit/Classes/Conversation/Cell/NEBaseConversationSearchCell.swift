
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBaseConversationSearchCell: TextBaseCell {
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  public var searchModel: ConversationSearchListModel? {
    didSet {
      if let _ = searchModel {
        if let userFriend = searchModel?.userInfo {
          titleLabel.text = userFriend.showName()
          subTitleLabel.text = userFriend.user?.accountId

          if let imageName = userFriend.user?.avatar, !imageName.isEmpty {
            headImageView.setTitle("")
            headImageView.sd_setImage(with: URL(string: imageName), completed: nil)
            headImageView.backgroundColor = .clear
          } else {
            headImageView.setTitle(userFriend.showName() ?? "")
            headImageView.sd_setImage(with: nil, completed: nil)
            headImageView.backgroundColor = UIColor.colorWithString(string: userFriend.user?.accountId)
          }
        }
        if let teamInfo = searchModel?.team {
          titleLabel.text = teamInfo.getShowName()
          subTitleLabel.text = nil
          if let imageName = teamInfo.avatar, !imageName.isEmpty {
            headImageView.setTitle("")
            headImageView.sd_setImage(with: URL(string: imageName), completed: nil)
            headImageView.backgroundColor = .clear
          } else {
            headImageView.setTitle(teamInfo.getShowName())
            headImageView.sd_setImage(with: nil, completed: nil)
            headImageView.backgroundColor = UIColor.colorWithString(string: teamInfo.teamId)
          }
        }
      }
    }
  }

  public var searchText: String = "" {
    didSet {
      if let titleText = titleLabel.text {
        let attributedStr = NSMutableAttributedString(string: titleText)
        // range 表示从索引几开始取几个字符
        let range = attributedStr.mutableString.range(of: searchText)
        attributedStr.addAttribute(
          .foregroundColor,
          value: getRangeTextColor(),
          range: range
        )
        titleLabel.attributedText = attributedStr
        titleLabelCenterYAnchor?.isActive = true
        titleLabelTopAnchor?.isActive = false
        subTitleLabel.isHidden = true
      }

      if let subTitleText = subTitleLabel.text {
        let attributedStr = NSMutableAttributedString(string: subTitleText)
        // range 表示从索引几开始取几个字符
        let range = attributedStr.mutableString.range(of: searchText)
        attributedStr.addAttribute(
          .foregroundColor,
          value: getRangeTextColor(),
          range: range
        )
        subTitleLabel.attributedText = attributedStr
        subTitleLabel.isHidden = false
        titleLabelTopAnchor?.isActive = true
        titleLabelCenterYAnchor?.isActive = false
      }
    }
  }

  func getRangeTextColor() -> UIColor {
    UIColor.ne_blueText
  }
}
