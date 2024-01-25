
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreAudio
import Foundation
import NECoreIMKit
import NIMSDK
import simd

@objcMembers
open class MessageContentModel: NSObject, MessageModel {
  public var offset: CGFloat = 0
  open func cellHeight() -> CGFloat {
    CGFloat(height) + offset
  }

  public var isReplay: Bool = false
  public var showSelect: Bool = false // 多选按钮是否展示
  public var isSelected: Bool = false // 多选是否选中
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

  public var pinAccount: String?
  public var pinShowName: String?
  public var type: MessageType = .custom
  public var message: NIMMessage?
  public var contentSize = CGSize(width: 32.0, height: chat_min_h)
  public var height: CGFloat = 48
  public var shortName: String? // 昵称 > uid
  public var fullName: String? // 备注 >（群昵称）> 昵称 > uid
  public var avatar: String?
  public var replyText: String?
  public var fullNameHeight: CGFloat = 0
  public var isRevokedText: Bool = false
  public var timeOut = false

  public var replyedModel: MessageModel? {
    didSet {
      if let reply = replyedModel as? MessageContentModel, reply.isReplay == true {
        type = .reply
        replyText = ReplyMessageUtil.textForReplyModel(model: reply)
        // height 计算移至 getMessageModel(model:)
      }
    }
  }

  public var isRevoked: Bool = false {
    didSet {
      if isRevoked {
        type = .revoke
        if let time = message?.timestamp {
          let date = Date()
          let currentTime = date.timeIntervalSince1970
          if currentTime - time > 60 * 2 {
            timeOut = true
          }
        }
        // 只有文本消息，才计算可编辑按钮的宽度
        if let isSend = message?.isOutgoingMsg, isSend, message?.messageType == .text, timeOut == false {
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

  public var isPined: Bool = false {
    didSet {
      if isPined {
        height += chat_pin_height
      } else if oldValue {
        height -= chat_pin_height
      }
    }
  }

  // 是否显示时间
  public var timeContent: String? {
    didSet {
      if let time = timeContent, !time.isEmpty, time != oldValue {
        height += chat_timeCellH
      }
    }
  }

  public required init(message: NIMMessage?) {
    self.message = message
    if message?.session?.sessionType == .team,
       !IMKitClient.instance.isMySelf(message?.from) {
      fullNameHeight = NEKitChatConfig.shared.ui.messageProperties.showTeamMessageNick ? 20 : 0
    }
    height = contentSize.height + chat_content_margin * 2 + fullNameHeight
  }
}
