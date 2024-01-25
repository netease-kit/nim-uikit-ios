
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

@objc
public enum SettingCellType: Int {
  case SettingArrowCell = 0
  case SettingSwitchCell
  case SettingSelectCell
  case SettingHeaderCell
  case SettingTeamUserCell
  case SettingSubtitleCell
  case SettingSubtitleCustomCell
}

@objcMembers
open class SettingCellModel: NSObject {
  public typealias SwitchChangeCompletion = (Bool) -> Void
  public typealias CellClick = () -> Void
  public var cellName: String?
  public var subTitle: String?
  public var type = SettingCellType.SettingArrowCell.rawValue
  public var swichChange: SwitchChangeCompletion?
  public var rowHeight: CGFloat = 49
  public var titleWidth: CGFloat = 32
  public var cornerType = CornerType.none
  public var headerUrl: String?
  public var cellClick: CellClick?
  public var switchOpen = false
  // 头像扩展字段
  public var defaultHeadData: String?
  // 自定义视图的icon
  public var rightCustomViewIcon: String?
  // 自定义视图的点击事件
  public var customViewClick: CellClick?

  override public init() {}
}
