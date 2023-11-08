
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CoreAudio
import Foundation
import NECoreIMKit
import NIMSDK
import simd

@objcMembers
public class MessageContentModel: NSObject, MessageModel {
  public var offset: CGFloat = 0
  public func cellHeight() -> CGFloat {
    CGFloat(height) + offset
  }

  public var isReplay: Bool = false

  public var pinAccount: String?
  public var pinShowName: String?
  public var type: MessageType = .custom
  public var message: NIMMessage?
  public var contentSize = CGSize(width: 32.0, height: chat_min_h)
  public var height: Float = 48
  public var shortName: String? // 昵称 > uid
  public var fullName: String? // 备注 >（群昵称）> 昵称 > uid
  public var avatar: String?
  public var replyText: String?
  public var fullNameHeight: Float = 0
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
        height = Float(contentSize.height + chat_content_margin) + fullNameHeight
      } else {
        type = .custom
        contentSize = CGSize(width: 32.0, height: chat_min_h)
        height = Float(chat_min_h + chat_content_margin) + fullNameHeight
      }
    }
  }

  public var isPined: Bool = false {
    didSet {
      if isPined {
        height = Float(contentSize.height + chat_content_margin) + fullNameHeight + Float(chat_pin_height)
      } else {
        height = Float(contentSize.height + chat_content_margin) + fullNameHeight
      }
    }
  }

  public required init(message: NIMMessage?) {
    self.message = message
    if message?.session?.sessionType == .team,
       !IMKitClient.instance.isMySelf(message?.from) {
      fullNameHeight = 20
    }
    print("self.fullNameHeight\(fullNameHeight)")
  }
}
