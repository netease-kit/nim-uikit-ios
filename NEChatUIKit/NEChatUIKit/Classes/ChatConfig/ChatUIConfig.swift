
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECommonKit

/// 头像枚举类型
@objc public enum NEChatAvatarType: Int {
  case rectangle = 1 // 矩形
  case cycle // 圆形
}

@objcMembers
public class ChatUIConfig: NSObject {
  /// UI 元素自定义

  // 头像圆角大小
  public var avatarCornerRadius: CGFloat?

  // 头像类型
  public var avatarType: NEChatAvatarType?

  // 设置聊天消息标记的背景色
  public var signalBgColor = UIColor.ne_yellowBackgroundColor

  // 时间颜色
  public var timeTextColor = UIColor.ne_emptyTitleColor

  // 时间字体大小
  public var timeTextSize: CGFloat = 14

  // 右侧聊天背景气泡
  public var rightBubbleBg: UIImage?

  // 左侧聊天背景气泡
  public var leftBubbleBg: UIImage?

  // 聊天字体大小(文本类型)
  public var messageTextSize = UIFont.systemFont(ofSize: 16)

  // 聊天字体颜色(文本类型)
  public var messageTextColor = UIColor.ne_darkText

  // 自己发送的消息体的背景色
  public var selfMessageBg: UIColor = .clear

  // 接收到的消息体的背景色
  public var receiveMessageBg: UIColor = .clear

  // 不设置头像的用户所展示的文字头像中的文字颜色
  public var userNickColor: UIColor = .white

  // 不设置头像的用户所展示的文字头像中的文字字体大小
  public var userNickTextSize: CGFloat = 12

  // 单聊中是否展示已读未读状态
  public var showP2pMessageStatus: Bool = true
  // 群聊中是否展示已读未读状态
  public var showTeamMessageStatus: Bool = true
  // 会话界面是否展示标题栏
  public var showTitleBar: Bool = true
  // 是否展示标题栏右侧图标按钮
  public var showTitleBarRightIcon: Bool = true
  // 设置标题栏右侧图标按钮展示图标
  public var titleBarRightRes: UIImage?
  // 标题栏右侧图标的点击事件
  public var titleBarRightClick: (() -> Void)?
  // 设置会话界面背景色
  public var chatViewBackground: UIColor?

  /// 用户可自定义参数

  // 发送文件大小限制(单位：MB)
  public var fileSizeLimit: Double = 200
}
