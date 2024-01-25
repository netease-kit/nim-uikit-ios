
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objcMembers
open class SettingSectionModel: NSObject {
  public var cellModels = [SettingCellModel]()
  override public init() {}

  // 设置圆角
  open func setCornerType() {
    cellModels.forEach { model in
      if model == cellModels.first {
        model.cornerType = .topLeft.union(.topRight)
        if model == cellModels.last {
          model.cornerType = .topLeft.union(.topRight).union(.bottomLeft).union(.bottomRight)
        }
      } else if model == cellModels.last {
        model.cornerType = .bottomLeft.union(.bottomRight)
      } else {
        model.cornerType = .none
      }
    }
  }
}
