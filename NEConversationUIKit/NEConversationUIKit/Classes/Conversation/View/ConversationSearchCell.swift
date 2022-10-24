
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class ConversationSearchCell: TextBaseCell {
  public var searchModel: ConversationSearchListModel? {
    didSet {
      if let _ = searchModel {
        if let userInfo = searchModel?.userInfo {
          titleLabel.text = userInfo.showName()

          if let imageName = userInfo.userInfo?.avatarUrl {
            headImge.setTitle("")
            headImge.sd_setImage(with: URL(string: imageName), completed: nil)
          } else {
            headImge.setTitle(userInfo.showName() ?? "")
            headImge.sd_setImage(with: nil, completed: nil)
            headImge.backgroundColor = UIColor.colorWithString(string: userInfo.userId)
          }
        }
        if let teamInfo = searchModel?.teamInfo {
          titleLabel.text = teamInfo.getShowName()
          if let imageName = teamInfo.avatarUrl {
            headImge.setTitle("")
            headImge.sd_setImage(with: URL(string: imageName), completed: nil)
          } else {
            headImge.setTitle(teamInfo.getShowName())
            headImge.sd_setImage(with: nil, completed: nil)
            headImge.backgroundColor = UIColor.colorWithString(string: teamInfo.teamId)
          }
        }
      }
    }
  }

  public var searchText: String = "" {
    didSet {
      if let titleText = titleLabel.text,
         let range = titleText.findAllIndex(searchText).first {
        let attributedStr = NSMutableAttributedString(string: titleText)
        // range必须要加，参数分别表示从索引几开始取几个字符
        attributedStr.addAttribute(
          .foregroundColor,
          value: UIColor.ne_blueText,
          range: range
        )
        titleLabel.attributedText = attributedStr
      }
    }
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
