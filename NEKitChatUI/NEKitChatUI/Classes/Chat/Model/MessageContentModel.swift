
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
import NIMSDK
import CoreAudio
import simd
import NEKitCoreIM

public class MessageContentModel: MessageModel {
    
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
    public var replyedModel: MessageModel? {
        didSet {
            if let reply = replyedModel as? MessageContentModel {
                replyText = ReplyMessageUtil.textForReplyModel(model: reply)
                if let t = replyText {
                    let size = String.getTextRectSize(t, font: UIFont.systemFont(ofSize: 12.0), size: CGSize(width: qChat_content_maxW, height: CGFloat.greatestFiniteMagnitude))
                    contentSize = CGSize(width: max(contentSize.width, size.width), height: contentSize.height + chat_reply_height)
                    height = Float(contentSize.height + qChat_margin) + self.fullNameHeight
                }
            }
        }
    }
    
    public var isRevoked: Bool = false {
        didSet {
            if isRevoked {
                type = .revoke
                if let isSend = self.message?.isOutgoingMsg, isSend {
                    contentSize = CGSize(width: 218, height: qChat_min_h)
                }else {
                    contentSize = CGSize(width: 130, height: qChat_min_h)
                }
                height = Float(contentSize.height + qChat_margin) + self.fullNameHeight
            }else {
                type = .custom
                contentSize = CGSize(width: 32.0, height: qChat_min_h)
                height = Float(qChat_min_h + qChat_margin) + self.fullNameHeight
            }
        }
    }
    
    public var isPined: Bool = false {
        didSet {
            if isPined {
                height = Float(contentSize.height + qChat_margin + chat_pin_height) + self.fullNameHeight
            }else {
                height = Float(contentSize.height + qChat_margin) + self.fullNameHeight
            }
        }
    }
    
    required public init(message: NIMMessage?) {
        self.message = message
        contentSize = CGSize(width: 32.0, height: qChat_min_h)
        if message?.session?.sessionType == .team && !IMKitLoginManager.instance.isMySelf(message?.from) {
            self.fullNameHeight = 20
        }
        print("self.fullNameHeight\(self.fullNameHeight)")
        height = Float(qChat_min_h + qChat_margin) + self.fullNameHeight
    }

}
