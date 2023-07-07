
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 头像枚举类型
@objc
public enum NEConversationAvatarType: Int {
  case rectangle = 1 // 矩形
  case cycle // 圆形
}

@objcMembers
public class ConversationUIConfig: NSObject {
  /// 头像圆角大小
  public var avatarCornerRadius = 4.0

  /// 头像类型
  public var avatarType: NEConversationAvatarType?

  /// 是否隐藏导航栏
  public var hiddenNav = false

  /// 是否隐藏搜索按钮
  public var hiddenSearchBtn = false

  /// 是否把顶部添加按钮和搜索按钮都隐藏
  public var hiddenRightBtns = false

  // 主标题字体大小
  public var titleFont: UIFont?

  // 副标题字体大小
  public var subTitleFont = UIFont.systemFont(ofSize: 13)

  // 主标题字体颜色
  public var titleColor = UIColor.ne_darkText

  // 副标题字体颜色
  public var subTitleColor = UIColor.ne_lightText

  /// 时间字体颜色
  public var timeColor = UIColor(hexString: "0xcccccc")

  /// 时间字体大小
  public var timeFont = UIFont.systemFont(ofSize: 12)

  /// 会话列表 cell 左划置顶按钮文案内容
  public var stickTopBottonTitle = localizable("stickTop")
  /// 会话列表 cell 左划取消置顶按钮文案内容
  public var stickTopBottonCancelTitle = localizable("cancel_stickTop")
  /// 会话列表 cell 左划置顶按钮文案颜色
  public var stickTopBottonColor = NEConstant.hexRGB(0x337EFF)

  /// 会话列表 cell 左划删除按钮文案内容
  public var deleteBottonTitle = localizable("delete")
  /// 会话列表 cell 左划删除按钮文案颜色
  public var deleteBottonColor: UIColor?
}
