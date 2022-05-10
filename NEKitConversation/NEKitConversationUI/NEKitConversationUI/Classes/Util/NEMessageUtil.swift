
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import Foundation
import NIMSDK
public class NEMessageUtil {
    
    /// last message
    /// - Parameter message: message
    /// - Returns: result
    class func messageContent(message:NIMMessage) ->String {
        var text = ""
        switch message.messageType {
        case .text:
            if let messageText = message.text {
                text = messageText
            }
            break
        case .audio:
            text = "[语音]"
            break
        case .image:
            text = "[图片]"
            break
        case .video:
            text = "[视屏]"
            break
        case .location:
            text = "[位置]"
            break
        case .notification:
            text = "[通知]"
            break
        case .file:
            text = "[文件]"
            break
        case .tip:
            if let messageText = message.text {
                text = messageText
            }
            break
        case .rtcCallRecord:
            let record = message.messageObject as? NIMRtcCallRecordObject
            text = (record?.callType == .audio) ? "[网络通话]":"[视频聊天]"
            break
        default:
            text = "[未知消息]"
        }
        
        return text
    }
}
 
