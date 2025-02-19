
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

/// 头像枚举类型
@objc
public enum NELocalConversationAvatarType: Int {
  case rectangle = 1 // 矩形
  case cycle // 圆形
}

/// 会话模块自定义配置
@objcMembers
public class LocalConversationUIConfig: NSObject {
  public static let shared = LocalConversationUIConfig()

  /// 是否展示界面顶部的标题栏
  public var showTitleBar = true

  /// 是否展示标题栏左侧图标
  public var showTitleBarLeftIcon = true

  /// 是否展示标题栏次最右侧图标
  public var showTitleBarRight2Icon = true

  /// 是否展示标题栏最右侧图标
  public var showTitleBarRightIcon = true

  /// 标题栏左侧图标
  public var titleBarLeftRes: UIImage?

  /// 标题栏最右侧图标
  public var titleBarRightRes: UIImage?

  /// 标题栏次最右侧图标
  public var titleBarRight2Res: UIImage?

  /// 标题栏的文案
  public var titleBarTitle: String?

  /// 标题栏的颜色值
  public var titleBarTitleColor: UIColor?

  /// 会话列表页面的 UI 个性化定制
  public var conversationProperties = LocalConversationProperties()

  /// 会话列表 cell 左划置顶按钮文案内容
  public var stickTopButtonTitle: String?
  /// 会话列表 cell 左划取消置顶按钮文案内容(会话置顶后生效)
  public var stickTopButtonCancelTitle: String?
  /// 会话列表 cell 左划置顶按钮背景颜色
  public var stickTopButtonBackgroundColor: UIColor?
  /// 会话列表 cell 左划置顶按钮点击事件
  public var stickTopButtonClick: ((NEBaseLocalConversationController, NELocalConversationListModel?, IndexPath) -> Void)?

  /// 会话列表 cell 左划删除按钮文案内容
  public var deleteButtonTitle: String?
  /// 会话列表 cell 左划删除按钮背景颜色
  public var deleteButtonBackgroundColor: UIColor?
  /// 会话列表 cell 左划删除按钮点击事件
  public var deleteButtonClick: ((NEBaseLocalConversationController, NELocalConversationListModel?, IndexPath) -> Void)?

  /// 标题栏左侧按钮点击事件
  public var titleBarLeftClick: ((NEBaseLocalConversationController) -> Void)?

  /// 标题栏最右侧按钮点击事件
  public var titleBarRightClick: ((NEBaseLocalConversationController) -> Void)?

  /// 标题栏次最右侧按钮点击事件
  public var titleBarRight2Click: ((NEBaseLocalConversationController) -> Void)?

  /// 会话列表点击事件
  public var itemClick: ((NEBaseLocalConversationController, NELocalConversationListModel?, IndexPath) -> Void)?

  /// 会话列表的视图控制器回调，回调中会返回会话列表的视图控制器
  public var customController: ((NEBaseLocalConversationController) -> Void)?
}

/// 会话列表页面的 UI 个性化定制
@objcMembers
public class LocalConversationProperties: NSObject {
  /// 头像圆角大小
  public var avatarCornerRadius = 0.0

  /// 头像类型
  public var avatarType: NELocalConversationAvatarType = .rectangle

  /// 未被置顶的会话项的背景色
  public var itemBackground: UIColor?

  /// 置顶的会话项的背景色
  public var itemStickTopBackground: UIColor?

  // 会话标题的字体大小
  public var itemTitleSize: CGFloat = 0

  // 会话消息缩略内容的字体大小
  public var itemContentSize: CGFloat = 0

  /// 时间字体大小
  public var itemDateSize: CGFloat = 0

  // 会话标题的字体颜色
  public var itemTitleColor = UIColor.ne_darkText

  // 会话消息缩略内容的字体颜色
  public var itemContentColor = UIColor.ne_lightText

  /// 会话时间的字体颜色
  public var itemDateColor = UIColor(hexString: "0xcccccc")
}
