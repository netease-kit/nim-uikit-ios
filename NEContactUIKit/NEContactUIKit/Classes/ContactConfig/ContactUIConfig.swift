
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
/// 头像枚举类型
@objc public enum NEContactAvatarType: Int {
  case rectangle = 1 // 矩形
  case cycle // 圆形
}

@objcMembers
public class ContactUIConfig: NSObject {
  /// 头像圆角大小
  public var avatarCornerRadius = 4.0

  /// 头像类型
  public var avatarType: NEContactAvatarType = .cycle

  // 通讯录标题大小
  public var titleFont = UIFont.systemFont(ofSize: 14)

  /// 通讯录标题颜色
  public var titleColor = UIColor.ne_darkText

  /// 是否隐藏通讯录搜索按钮
  public var hiddenSearchBtn = false

  /// 是否把顶部添加好友和搜索按钮都隐藏
  public var hiddenRightBtns = false

  /// 通讯录间隔线颜色
  public var divideLineColor = UIColor.ne_borderColor

  /// 检索标题字体颜色
  public var indexTitleColor = UIColor.ne_emptyTitleColor
}
