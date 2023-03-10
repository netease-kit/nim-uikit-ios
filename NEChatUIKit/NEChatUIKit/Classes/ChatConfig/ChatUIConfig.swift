
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
  /// 头像圆角大小
  public var avatarCornerRadius = 4.0

  /// 头像类型
  public var avatarType: NEChatAvatarType = .cycle

  /// 设置聊天消息标记的背景色
  public var chatPinColor = UIColor.ne_yellowBackgroundColor

  // 时间颜色
  public var timeColor = UIColor.ne_emptyTitleColor

  // 右侧聊天背景气泡
  public var rightBubbleBg = UIImage.ne_imageNamed(name: "chat_message_send")

  // 左侧聊天背景气泡
  public var leftBubbleBg = UIImage.ne_imageNamed(name: "chat_message_receive")

  /// 聊天字体大小(文本类型)
  public var messageFont = UIFont.systemFont(ofSize: 16)

  /// 聊天字体颜色(文本类型)
  public var messageColor = UIColor.ne_darkText

  /// 发送文件大小限制(单位：MB)
  public var fileSizeLimit: Double = 200
}
