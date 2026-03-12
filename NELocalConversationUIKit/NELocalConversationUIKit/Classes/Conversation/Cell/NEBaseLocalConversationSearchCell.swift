
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBaseLocalConversationSearchCell: TextBaseCell {
  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  public var searchModel: ConversationSearchListModel? {
    didSet {
      if let _ = searchModel {
        if let userFriend = searchModel?.userInfo {
          let url = userFriend.user?.avatar
          let name = userFriend.shortName() ?? ""
          let accountId = userFriend.user?.accountId ?? ""
          headImageView.configHeadData(headUrl: url, name: name, uid: accountId)

          titleLabel.text = userFriend.showName()
          subTitleLabel.text = userFriend.user?.accountId
        }

        if let teamInfo = searchModel?.team {
          let url = teamInfo.avatar
          let name = teamInfo.getShortName()
          let accountId = teamInfo.teamId
          headImageView.configHeadData(headUrl: url, name: name, uid: accountId)

          titleLabel.text = teamInfo.getShowName()
          subTitleLabel.text = nil
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
    UIColor.ne_normalTheme
  }
}
