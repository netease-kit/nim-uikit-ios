
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objc
public enum MessageType: Int {
  case text = 1
  case image
  case audio
  case video
  case location
  case notification
  case file
  case tip
  case robot
  case rtcCallRecord
  case custom
  case time
  case revoke
  case reply

  /// 合并转发消息
  case multiForward

  /// 带标题的文本消息
  case richText
}

@objc
public protocol MessageModel: NSObjectProtocol {
  var message: NIMMessage? { get set }
  // 气泡区域的大小 不包含气泡上下到cell上下的边距
  var contentSize: CGSize { get set }
  var height: CGFloat { get set }
//    名字后2位
  var shortName: String? { get set }
//    名字全长
  var fullName: String? { get set }
  var avatar: String? { get set }
  var type: MessageType { get set }
  var isRevoked: Bool { get set }
  var isPined: Bool { get set }
//    userID
  var pinAccount: String? { get set }
  var pinShowName: String? { get set }
//    被回复的消息
  var replyedModel: MessageModel? { get set }
  var replyText: String? { get set }
  var isRevokedText: Bool { get set }
  var isReplay: Bool { get set }
  var showSelect: Bool { get set } // 多选按钮是否展示
  var isSelected: Bool { get set } // 多选是否选中
  var inMultiForward: Bool { get set } // 是否是合并消息中的子消息

  var timeContent: String? { get set } // 具体时间

  init(message: NIMMessage?)

  var offset: CGFloat { get set }

  func cellHeight() -> CGFloat
}
