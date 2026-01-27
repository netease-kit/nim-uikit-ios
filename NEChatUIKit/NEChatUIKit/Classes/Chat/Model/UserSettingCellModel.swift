
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
  public typealias SwitchChangeCompletion = (Bool) -> Void
  public typealias CellClick = () -> Void
  public var cellName: String?
  public var subTitle: String?
//  var type = SettingCellType.SettingArrowCell.rawValue
  public var swichChange: SwitchChangeCompletion?
  public var rowHeight: CGFloat = 49
  public var cornerType = CornerType.none
//  var headerUrl: String?
  public var cellClick: CellClick?
  public var switchOpen = false
  public var type = UserSettingType.SwitchType.rawValue
}
