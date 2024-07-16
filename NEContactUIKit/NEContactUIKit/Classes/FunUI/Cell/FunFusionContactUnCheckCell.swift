//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunFusionContactUnCheckCell: FunContactUnCheckCell {
  override func configure(_ model: Any) {
    if let cellModel = model as? NEFusionContactCellModel {
      if cellModel.user != nil {
        avatarImageView.configHeadData(
          headUrl: cellModel.user?.user?.avatar,
          name: cellModel.getShowName(),
          uid: cellModel.getAccountId()
        )
      } else if cellModel.aiUser != nil {
        avatarImageView.configHeadData(
          headUrl: cellModel.aiUser?.avatar,
          name: cellModel.getShowName(),
          uid: cellModel.getAccountId()
        )
      }
    }
  }
}
