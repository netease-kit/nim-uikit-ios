
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

/// 消息模块自定义配置
@objcMembers
public class ChatUIConfig: NSObject {
  public static let shared = ChatUIConfig()

  /// 消息页面的 UI 个性化定制
  public var messageItemClick: ((NEChatBaseViewController, UITableViewCell, MessageContentModel?) -> Void)?

  /// 消息页面的 UI 个性化定制
  public var messageProperties = MessageProperties()

  /// 文本输入框下方 tab 按钮定制
  public var chatInputBar: ((ChatViewController?, inout [UIButton]) -> Void)?

  /// 【更多】区域功能列表
  public var chatInputMenu: ((ChatViewController, inout [NEMoreItemModel]) -> Void)?

  /// 消息长按弹出菜单回调, 回调中会返回长按弹出菜单列表
  public var chatPopMenu: ((ChatViewController, inout [OperationItem], MessageContentModel?) -> Void)?

  /// 消息长按弹出菜单点击事件回调
  public var popMenuClick: ((ChatViewController, OperationItem) -> Void)?

  /// 消息列表的视图控制器回调，回调中会返回消息列表的视图控制器
  public var customController: ((ChatViewController) -> Void)?

  /// 消息列表的 AI 助聊视图控制器回调，回调中会返回消息列表的 AI 助聊视图控制器
  public var aiChatViewController: ((AIChatViewController) -> Void)?

  /// AI 助聊的数据加载器
  /// 参数分别为：上下文消息、回调
  public var aiChatDataLoader: (([V2NIMMessage]?, @escaping ([AIChatCellModel]?, Error?) -> Void) -> Void)?

  /// AI 助聊入口按钮点击事件，仅在展开时回调
  /// 参数分别为：AI 助聊视图控制器、上下文消息
  public var aiChatDidClick: ((AIChatViewController, [V2NIMMessage]?) -> Void)?

  /// AI 助聊重新加载按钮点击事件
  /// 参数分别为：AI 助聊视图控制器、上下文消息
  public var aiChatReloadClick: ((AIChatViewController, [V2NIMMessage]?) -> Void)?

  /*
   * 用户可自定义参数
   */

  /// 发送文件大小限制(单位：MB)
  public var fileSizeLimit: Double = 200

  /// 群未读显示限制数，默认超过200人不显示已读未读进度
  public var maxReadingNum = 200

  /// 撤回消息可重新编辑时间 (单位：min)
  public var revokeEditTimeGap: Int = 2

  /// 消息可撤回时间 (单位：min)
  private var revokeTimeGap: Int = 10080

  /// 设置消息可撤回时间 (单位：min)
  /// 周期为[2,  7*24*60] 分钟, 超过最大值， 修正为最大值， 最小值修正到2分钟
  open func setRevokeTimeGap(_ time: Int) {
    revokeTimeGap = max(time, 2) // >= 2 min
    revokeTimeGap = min(revokeTimeGap, 10080) // <= 7 d
  }

  /// 获取消息可撤回时间 (单位：min)
  /// 周期为[2,  7*24*60] 分钟
  open func getReeditTimeGap() -> Int {
    revokeTimeGap
  }
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

  // 输入框文本字体颜色
  public var inputTextColor = UIColor.ne_darkText

  // 输入框占位文本字体颜色
  public var inputPlaceholderTextColor: UIColor?

  // 自己发送的消息体的背景色
  public var selfMessageBg: UIColor = .clear

  // 接收到的消息体的背景色
  public var receiveMessageBg: UIColor = .clear

  // 背景图片拉伸参数（边距偏移）
  public var backgroundImageCapInsets: UIEdgeInsets? = UIEdgeInsets(top: 35, left: 25, bottom: 10, right: 25)

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
  public var titleBarRightClick: ((ChatViewController) -> Void)?
  // 设置消息列表背景色，仅消息列表生效
  public var chatTableViewBackgroundColor: UIColor?

  // 设置聊天界面背景色，包含状态栏、导航栏、消息列表、输入区域，颜色同 chatViewBackgroundColor
  public var chatViewBackgroundSolid: Bool = false
}
