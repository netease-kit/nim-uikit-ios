
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
  // 标题栏文案
  public var title: String?

  /// 标题栏文案颜色
  public var titleColor: UIColor?

  /// 是否展示标题栏
  public var showTitleBar = true

  /// 是否展示标题栏的次最右侧图标
  public var showTitleBarRight2Icon = true

  /// 是否展示标题栏的最右侧图标
  public var showTitleBarRightIcon = true

  /// 标题栏的最右侧图标
  public var titleBarRightRes: UIImage?

  /// 标题栏的次最右侧图标
  public var titleBarRight2Res: UIImage?

  /// 标题栏最右侧按钮点击事件
  public var titleBarRightClick: (() -> Void)?

  /// 标题栏次最右侧按钮点击事件
  public var titleBarRight2Click: (() -> Void)?

  /// 是否在通讯录界面显示头部模块
  public var showHeader = true

  /// 通讯录列表头部模块的数据回调
  public var headerData: (([ContactHeadItem]) -> Void)?

  /// 通讯录列表头部模块 cell 点击事件
  public var headerItemClick: ((ContactInfo, IndexPath) -> Void)?

  /// 通讯录列表好友 cell 点击事件
  public var friendItemClick: ((ContactInfo, IndexPath) -> Void)?

  /// 通讯录好友列表的 UI 个性化定制
  public var contactProperties = ContactProperties()

  /// 通讯录列表的视图控制器回调，回调中会返回通讯录列表的视图控制器
  public var customController: ((NEBaseContactsViewController) -> Void)?
}

/// 通讯录页面的 UI 个性化定制
@objcMembers
public class ContactProperties: NSObject {
  /// 头像圆角大小
  public var avatarCornerRadius = 4.0

  /// 头像类型
  public var avatarType: NEContactAvatarType?

  // 通讯录好友标题大小
  public var itemTitleSize: CGFloat = 0

  /// 通讯录好友标题颜色
  public var itemTitleColor = UIColor.ne_darkText

  /// 通讯录间隔线颜色
  public var divideLineColor = UIColor.ne_borderColor

  /// 检索标题字体颜色
  public var indexTitleColor: UIColor?
}
