
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
public class HistoryMessageModel: NSObject {
  // 消息发送者全称
  public var fullName: String?
  // 消息发送者简称
  public var shortName: String?
  // 消息发送者头像
  public var avatar: String?
  // 历史记录
  public var content: String?
  // 消息发送时间
  public var time: String?
  // 消息体
  public var imMessage: V2NIMMessage?

  override public init() {}
}
