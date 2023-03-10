
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK
import CoreAudio
import simd
import NECoreIMKit

@objcMembers
public class MessageContentModel: NSObject, MessageModel {
  public var isReplay: Bool = false

  public var pinAccount: String?
  public var pinShowName: String?
  public var type: MessageType = .custom
  public var message: NIMMessage?
  public var contentSize: CGSize
  public var height: Float
  public var shortName: String?
  public var fullName: String?
  public var avatar: String?
  public var replyText: String?
  public var fullNameHeight: Float = 0
  public var isRevokedText: Bool = false
  public var timeOut = false

  public var replyedModel: MessageModel? {
    didSet {
      if let reply = replyedModel as? MessageContentModel, reply.isReplay == true {
        replyText = ReplyMessageUtil.textForReplyModel(model: reply)
        if let t = replyText {
          let size = String.getTextRectSize(
            t,
            font: UIFont.systemFont(ofSize: 12.0),
            size: CGSize(
              width: qChat_content_maxW,
              height: CGFloat.greatestFiniteMagnitude
            )
          )
          var width = size.width
          if replyedModel?.type == .location {
            let locationMinWidth: CGFloat = 76
            if width < locationMinWidth {
              width = locationMinWidth
            }
          }
          contentSize = CGSize(
            width: max(contentSize.width, width),
            height: contentSize.height + chat_reply_height
          )
          height = Float(contentSize.height + qChat_margin) + fullNameHeight
        }
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
          contentSize = CGSize(width: 218, height: qChat_min_h)
        } else {
          contentSize = CGSize(width: 130, height: qChat_min_h)
        }
        height = Float(contentSize.height + qChat_margin) + fullNameHeight
      } else {
        type = .custom
        contentSize = CGSize(width: 32.0, height: qChat_min_h)
        height = Float(qChat_min_h + qChat_margin) + fullNameHeight
      }
    }
  }

  public var isPined: Bool = false {
    didSet {
      if isPined {
        height = Float(contentSize.height + qChat_margin + chat_pin_height) + fullNameHeight
      } else {
        height = Float(contentSize.height + qChat_margin) + fullNameHeight
      }
    }
  }

  public required init(message: NIMMessage?) {
    self.message = message
    contentSize = CGSize(width: 32.0, height: qChat_min_h)
    if message?.session?.sessionType == .team,
       !IMKitEngine.instance.isMySelf(message?.from) {
      fullNameHeight = 20
    }
    print("self.fullNameHeight\(fullNameHeight)")
    height = Float(qChat_min_h + qChat_margin) + fullNameHeight
  }
}
