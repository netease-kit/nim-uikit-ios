//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
public class NELocalConversationListModel: NSObject, Comparable {
  public static func < (lhs: NELocalConversationListModel, rhs: NELocalConversationListModel) -> Bool {
    let time1 = lhs.conversation?.lastMessage?.messageRefer.createTime ?? lhs.conversation?.updateTime ?? 0
    let time2 = rhs.conversation?.lastMessage?.messageRefer.createTime ?? rhs.conversation?.updateTime ?? 0
    return time1 > time2
  }

  /// 会话
  public var conversation: V2NIMLocalConversation? {
    didSet {
      if let lastMessage = conversation?.lastMessage, lastMessage.messageType == .MESSAGE_TYPE_TEXT, let text = lastMessage.text {
        lastMessageConent = NEChatKitClient.instance.getEmojString(text, LocalConversationUIConfig.shared.conversationProperties.itemContentSize > 0 ? LocalConversationUIConfig.shared.conversationProperties.itemContentSize : 13)
      } else {
        lastMessageConent = nil
      }
    }
  }

  /// 自定义类型
  public var customType = 0

  /// 最后一条消息内容(包含表情解析)
  var lastMessageConent: NSAttributedString?
}
