
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public enum UserSettingType: Int {
  case SwitchType = 1
  case SelectType = 2
}

@objcMembers
open class UserSettingCellModel: NSObject {
  typealias SwitchChangeCompletion = (Bool) -> Void
  typealias CellClick = () -> Void
  var cellName: String?
  var subTitle: String?
//    var type = SettingCellType.SettingArrowCell.rawValue
  var swichChange: SwitchChangeCompletion?
  var rowHeight: CGFloat = 49
  var cornerType = CornerType.none
//    var headerUrl: String?
  var cellClick: CellClick?
  var switchOpen = false
  var type = UserSettingType.SwitchType.rawValue
}
