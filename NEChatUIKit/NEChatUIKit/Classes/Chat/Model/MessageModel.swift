
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
  var message: V2NIMMessage? { get set }
  var type: MessageType { get set }

  // 宽高
  var contentSize: CGSize { get set } // 气泡区域的大小 不包含气泡上下到cell上下的边距
  var offset: CGFloat { get set }
  var height: CGFloat { get set }
  func cellHeight() -> CGFloat

  // 名称头像
  var shortName: String? { get set } //    名字后2位
  var fullName: String? { get set } //    名字全长
  var avatar: String? { get set }

  // 标记
  var isPined: Bool { get set }
  var pinAccount: String? { get set }
  var pinShowName: String? { get set }

  // 回复
  var isReplay: Bool { get set }
  var replyedModel: MessageModel? { get set } // 被回复的消息
  var replyText: String? { get set }

  // 撤回
  var isRevoked: Bool { get set } // 消息是否已撤回
  var isReedit: Bool { get set } // 撤回消息是否可以重新编辑

  // 已读未读
  var readCount: Int { get set }
  var unreadCount: Int { get set }

  // 多选
  var showSelect: Bool { get set } // 多选按钮是否展示
  var isSelected: Bool { get set } // 多选是否选中

  var inMultiForward: Bool { get set } // 是否是合并消息中的子消息

  var timeContent: String? { get set } // 具体时间

  init(message: V2NIMMessage?)
}
