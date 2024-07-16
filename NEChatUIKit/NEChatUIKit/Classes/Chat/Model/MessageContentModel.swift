
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreAudio
import Foundation
import NEChatKit
import NECoreIM2Kit
import NIMSDK

@objcMembers
open class MessageContentModel: NSObject, MessageModel {
  public var type: MessageType = .custom // 消息类型（文本、图片、自定义消息...）
  public var customType: Int = 0 // 自定义消息的子类型（合并转发、换行消息...）
  public var message: V2NIMMessage?
  public weak var cell: NEBaseChatMessageCell? // 消息对应的cell

  public var offset: CGFloat = 0
  public var textWidth: CGFloat = 0
  public var contentSize = CGSize(width: 32.0, height: chat_min_h)
  public var height: CGFloat = 48
  open func cellHeight() -> CGFloat {
    CGFloat(height) + offset
  }

  public var selectRange: NSRange? // 划词选择的范围
  open func selectText() -> String? {
    nil
  }

  public var showSelect: Bool = false // 多选按钮是否展示
  public var isSelected: Bool = false // 多选是否选中
  public var isSelectAll: Bool = false // 是否全选
  public var unkonwMessage: Bool = false
  public var inMultiForward: Bool = false { // 是否是合并消息中的子消息
    didSet {
//      fullNameHeight = 0 // 合并消息中的子消息不显示昵称
      fullNameHeight = 20 // 合并消息中的子消息显示昵称
      if inMultiForward {
        height += fullNameHeight
      } else if oldValue {
        height -= fullNameHeight
      }
    }
  }

  public var avatar: String?
  public var shortName: String? // 昵称 > uid
  public var fullName: String? // 备注 >（群昵称）> 昵称 > uid
  public var fullNameHeight: CGFloat = 0

  public var readCount: Int = 0
  public var unreadCount: Int = 0

  public var isReplay: Bool = false
  public var replyText: String?
  public var replyedModel: MessageModel? {
    didSet {
      if let reply = replyedModel as? MessageContentModel, reply.isReplay == true {
        if type == .tip {
          replyedModel?.isReplay = false
          return
        }

        type = .reply
        replyText = ReplyMessageUtil.textForReplyModel(model: reply)
        // height 计算移至 getMessageModel(model:)
      }
    }
  }

  public var isReedit: Bool = false
  public var timeOut = false
  public var isRevoked: Bool = false {
    didSet {
      if isRevoked {
        type = .revoke
        if let time = message?.createTime {
          let date = Date()
          let currentTime = date.timeIntervalSince1970
          if currentTime - time > 60 * 2 {
            timeOut = true
          }
        }
        // 只有文本消息，才计算可编辑按钮的宽度
        if let isSend = message?.isSelf, isSend, message?.messageType == .MESSAGE_TYPE_TEXT, timeOut == false {
          contentSize = CGSize(width: 218, height: chat_min_h)
        } else {
          contentSize = CGSize(width: 130, height: chat_min_h)
        }
        height = contentSize.height + chat_content_margin + fullNameHeight

        // time
        if let time = timeContent, !time.isEmpty {
          height += chat_timeCellH
        }
      } else {
        type = .custom
        contentSize = CGSize(width: 32.0, height: chat_min_h)
        height = chat_min_h + chat_content_margin + fullNameHeight

        // time
        if let time = timeContent, !time.isEmpty {
          height += chat_timeCellH
        }
      }
    }
  }

  public var pinAccount: String?
  public var pinShowName: String?
  public var isPined: Bool = false

  // 是否显示时间
  public var timeContent: String? {
    didSet {
      if let time = timeContent, !time.isEmpty, time != oldValue {
        height += chat_timeCellH
      }
    }
  }

  public let messageTextFont = UIFont.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize)
  public let messageMaxSize = CGSize(width: chat_content_maxW, height: CGFloat.greatestFiniteMagnitude)

  public required init(message: V2NIMMessage?) {
    self.message = message
    if message?.conversationType == .CONVERSATION_TYPE_TEAM,
       let senderId = ChatMessageHelper.getSenderId(message),
       !IMKitClient.instance.isMe(senderId) {
      fullNameHeight = NEKitChatConfig.shared.ui.messageProperties.showTeamMessageNick ? 20 : 0
    }
    height = contentSize.height + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }
}
