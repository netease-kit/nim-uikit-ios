
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NIMSDK
import UIKit

/// 头像枚举类型
@objc public enum NEChatAvatarType: Int {
  case rectangle = 1 // 矩形
  case cycle // 圆形
}

@objcMembers
public class ChatUIConfig: NSObject {
  /// 消息页面的 UI 个性化定制
  public var messageItemClick: ((UITableViewCell, MessageContentModel?) -> Void)?

  /// 消息页面的 UI 个性化定制
  public var messageProperties = MessageProperties()

  /// 文本输入框下方 tab 按钮定制
  public var chatInputBar: ((inout [UIButton]) -> Void)?

  /// 【更多】区域功能列表
  public var chatInputMenu: ((inout [NEMoreItemModel]) -> Void)?

  /// 消息长按弹出菜单回调, 回调中会返回长按弹出菜单列表
  public var chatPopMenu: ((inout [OperationItem], MessageContentModel?) -> Void)?

  /// 消息长按弹出菜单点击事件回调
  public var popMenuClick: ((OperationItem) -> Void)?

  /// 消息列表的视图控制器回调，回调中会返回消息列表的视图控制器
  public var customController: ((ChatViewController) -> Void)?

  /// 消息列表发送消息时的视图控制器回调
  /// 回调参数：消息体和消息列表的视图控制器
  /// 返回值：是否继续发送消息
  public var onSendMessage: ((V2NIMMessage, ChatViewController) -> Bool)?

  /// 用户可自定义参数

  // 发送文件大小限制(单位：MB)
  public var fileSizeLimit: Double = 200
}

/// 消息页面的 UI 个性化定制
@objcMembers
public class MessageProperties: NSObject {
  // 头像圆角大小
  public var avatarCornerRadius: CGFloat = 0

  // 头像类型
  public var avatarType: NEChatAvatarType = .rectangle

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
  public var messageTextSize: CGFloat = 16

  // 聊天字体颜色(文本类型)
  public var messageTextColor = UIColor.ne_darkText

  // 自己发送的消息体的背景色
  public var selfMessageBg: UIColor = .clear

  // 接收到的消息体的背景色
  public var receiveMessageBg: UIColor = .clear

  // 背景图片拉伸参数（边距偏移）
  public var backgroundImageCapInsets = UIEdgeInsets(top: 35, left: 25, bottom: 10, right: 25)

  // 不设置头像的用户所展示的文字头像中的文字颜色
  public var userNickColor: UIColor = .white

  // 不设置头像的用户所展示的文字头像中的文字字体大小
  public var userNickTextSize: CGFloat = 12

  // 标记列表字体大小(文本类型)
  public var pinMessageTextSize: CGFloat = 14

  // 单聊中是否展示已读未读状态
  public var showP2pMessageStatus: Bool = true
  // 群聊中是否展示已读未读状态
  public var showTeamMessageStatus: Bool = true
  // 群聊中是否展示好友昵称
  public var showTeamMessageNick: Bool = true
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
}
